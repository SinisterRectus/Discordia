local uv = require('uv')
local json = require('json')
local class = require('class')
local miniz = require('miniz')
local timer = require('timer')
local websocket = require('coro-websocket')
local constants = require('constants')
local enums = require('enums')

local Mutex = require('utils/Mutex')
local Stopwatch = require('utils/Stopwatch')
local VoiceConnection = require('voice/VoiceConnection')

local logLevel = enums.logLevel
local inflate = miniz.inflate
local encode, decode, null = json.encode, json.decode, json.null
local format = string.format
local ws_parseUrl, ws_connect = websocket.parseUrl, websocket.connect
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local wrap = coroutine.wrap
local time = os.time

local GATEWAY_DELAY = constants.GATEWAY_DELAY
local GATEWAY_VERSION_VOICE = constants.GATEWAY_VERSION_VOICE
local SUPPORTED_MODE = constants.SUPPORTED_MODE

local IDENTIFY        = 0
local SELECT_PROTOCOL = 1
local READY           = 2
local HEARTBEAT       = 3
local DESCRIPTION     = 4
local SPEAKING        = 5
local HEARTBEAT_ACK   = 6
local RESUME          = 7
local HELLO           = 8
local RESUMED         = 9

local TEXT   = 1
local BINARY = 2
local CLOSE  = 8

local function connect(url)
	local options = assert(ws_parseUrl(url))
	options.pathname = format('/?v=%i', GATEWAY_VERSION_VOICE)
	return assert(ws_connect(options))
end

local function getMode(modes)
	for _, v in ipairs(modes) do
		if v == SUPPORTED_MODE then
			return v
		end
	end
end

local VoiceSocket = class('VoiceSocket')

for name in pairs(logLevel) do
	VoiceSocket[name] = function(self, fmt, ...)
		local client = self._client
		return client[name](client, format('Voice : %s', fmt), ...)
	end
end

-- TODO: bring common code from here and Shard into one base Socket class

function VoiceSocket:__init(state, manager)
	self._state = state
	self._manager = manager
	self._client = manager._client
	self._mutex = Mutex()
	self._sw = Stopwatch()
end

function VoiceSocket:connect(url)

	local success, res, read, write = pcall(connect, url)

	if success then
		self._read = read
		self._write = write
		self._reconnect = nil
		self:info('Connected to %s', url)
		self:handlePayloads()
		self:info('Disconnected')
		if self._connection then
			local connection = self._connection
			self._connection = nil
			self._manager:emit('disconnect', connection)
		end
	else
		self:error('Could not connect to %s (%s)', url, res)
	end

	-- TODO: reconnecting and resuming

end

function VoiceSocket:handlePayloads()

	local state = self._state
	local manager = self._manager

	for message in self._read do

		local opcode = message.opcode
		local payload = message.payload

		if opcode == BINARY then

			payload = inflate(payload, 1)

		elseif opcode == CLOSE then

			local code, i = ('>H'):unpack(payload)
			local msg = #payload > i and payload:sub(i) or 'Connection closed'
			self:warning('%i - %s', code, msg)
			break

		end

		self._manager:emit('raw', payload)
		payload = decode(payload, 1, null)

		local d = payload.d
		local op = payload.op

		self:debug('WebSocket OP %s', op)

		if op == HELLO then

			self:info('Received HELLO')
			self:startHeartbeat(d.heartbeat_interval * 0.75) -- NOTE: hotfix for API bug
			self:identify()

		elseif op == READY then

			self:info('Received READY')
			local mode = getMode(d.modes)
			if mode then
				self._state.ssrc = d.ssrc
				self:handshake(d.ip, d.port, mode) -- NOTE: still getting IP in payload?
			else
				self:error('%q encryption method not available', SUPPORTED_MODE)
				self:disconnect()
			end

		elseif op == RESUMED then

			self:info('Received RESUMED')

		elseif op == DESCRIPTION then

			if d.mode == SUPPORTED_MODE then
				local connection = VoiceConnection(d.secret_key, state, manager)
				self._connection = connection
				manager:emit('connect', connection)
			else
				self:error('%q encryption method not available', SUPPORTED_MODE)
				self:disconnect()
			end

		elseif op == HEARTBEAT_ACK then

			manager:emit('heartbeat', nil, self._sw.milliseconds) -- TODO: id

		elseif op then

			self:warning('Unhandled WebSocket payload OP %i', op)

		end

	end

end

local function send(self, op, d)
	if not self._write then
		return false, 'Not connected to gateway'
	end
	self._mutex:lock()
	local success, err = self._write {opcode = TEXT, payload = encode {op = op, d = d}}
	self._mutex:unlockAfter(GATEWAY_DELAY)
	return success, err
end

local function loop(self)
	wrap(self.heartbeat)(self)
end

function VoiceSocket:startHeartbeat(interval)
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = setInterval(interval, loop, self)
end

function VoiceSocket:stopHeartbeat()
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = nil
end

function VoiceSocket:heartbeat()
	self._sw:reset()
	return send(self, HEARTBEAT, time())
end

function VoiceSocket:identify()
	local state = self._state
	return send(self, IDENTIFY, {
		server_id = state.guild_id,
		user_id = state.user_id,
		session_id = state.session_id,
		token = state.token,
	})
end

function VoiceSocket:resume()
	local state = self._state
	return send(self, RESUME, {
		server_id = state.guild_id,
		session_id = state.session_id,
		token = state.token,
	})
end

function VoiceSocket:disconnect(reconnect)
	if not self._write then return end
	self._reconnect = not not reconnect
	self:stopHeartbeat()
	self._write()
	self._read = nil
	self._write = nil
end

function VoiceSocket:handshake(server_ip, server_port, mode)
	local udp = uv.new_udp()
	udp:recv_start(function(err, data)
		assert(not err, err)
		udp:recv_stop()
		local a, b = data:sub(-2):byte(1, 2)
		local client_ip = data:match('....(%Z+)')
		local client_port = a + b * 0x100
		return wrap(self.selectProtocol)(self, client_ip, client_port, mode)
	end)
	udp:send(string.rep('\0', 70), server_ip, server_port) -- NOTE: doesn't need SSRC?
end

function VoiceSocket:selectProtocol(address, port, mode)
	return send(self, SELECT_PROTOCOL, {
		protocol = 'udp',
		data = {
			address = address,
			port = port,
			mode = mode,
		}
	})
end

function VoiceSocket:setSpeaking(speaking)
	return send(self, SPEAKING, {
		speaking = speaking,
		delay = 0,
		ssrc = self._state.ssrc,
	})
end

return VoiceSocket
