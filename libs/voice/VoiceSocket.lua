local uv = require('uv')
local class = require('class')
local timer = require('timer')
local constants = require('constants')
local enums = require('enums')

local VoiceConnection = require('voice/VoiceConnection')
local WebSocket = require('client/WebSocket')

local logLevel = enums.logLevel
local format = string.format
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local wrap = coroutine.wrap
local time = os.time

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

local function getMode(modes)
	for _, v in ipairs(modes) do
		if v == SUPPORTED_MODE then
			return v
		end
	end
end

local VoiceSocket = class('VoiceSocket', WebSocket)

for name in pairs(logLevel) do
	VoiceSocket[name] = function(self, fmt, ...)
		local client = self._client
		return client[name](client, format('Voice : %s', fmt), ...)
	end
end

function VoiceSocket:__init(state, manager)
	WebSocket.__init(self, manager)
	self._state = state
	self._manager = manager
	self._client = manager._client
end

function VoiceSocket:handleDisconnect()
	-- TODO: reconnecting and resuming
	if self._connection then
		local connection = self._connection
		self._connection = nil
		self._manager:emit('disconnect', connection)
	end
end

function VoiceSocket:handlePayload(payload)

	local manager = self._manager

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
			local connection = VoiceConnection(d.secret_key, self)
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

local function loop(self)
	return wrap(self.heartbeat)(self)
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
	return self:_send(HEARTBEAT, time())
end

function VoiceSocket:identify()
	local state = self._state
	return self:_send(IDENTIFY, {
		server_id = state.guild_id,
		user_id = state.user_id,
		session_id = state.session_id,
		token = state.token,
	})
end

function VoiceSocket:resume()
	local state = self._state
	return self:_send(RESUME, {
		server_id = state.guild_id,
		session_id = state.session_id,
		token = state.token,
	})
end

function VoiceSocket:handshake(server_ip, server_port, mode)
	local udp = uv.new_udp()
	self._udp = udp
	self._ip = server_ip
	self._port = server_port
	udp:recv_start(function(err, data)
		assert(not err, err)
		udp:recv_stop()
		local a, b = data:sub(-2):byte(1, 2)
		local client_ip = data:match('....(%Z+)')
		local client_port = a + b * 0x100
		return wrap(self.selectProtocol)(self, client_ip, client_port, mode)
	end)
	return udp:send(string.rep('\0', 70), server_ip, server_port) -- NOTE: doesn't need SSRC?
end

function VoiceSocket:selectProtocol(address, port, mode)
	return self:_send(SELECT_PROTOCOL, {
		protocol = 'udp',
		data = {
			address = address,
			port = port,
			mode = mode,
		}
	})
end

function VoiceSocket:setSpeaking(speaking)
	return self:_send(SPEAKING, {
		speaking = speaking,
		delay = 0,
		ssrc = self._state.ssrc,
	})
end

return VoiceSocket
