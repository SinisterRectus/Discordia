local json = require('json')
local timer = require('timer')
local miniz = require('miniz')
local websocket = require('coro-websocket')

local Emitter = require('utils/Emitter')
local Mutex = require('utils/Mutex')
local Stopwatch = require('utils/Stopwatch')
local EventHandler = require('client/EventHandler')

local constants = require('constants')
local enums = require('enums')

local logLevel = enums.logLevel
local inflate = miniz.inflate
local min, max, random = math.min, math.max, math.random
local encode, decode, null = json.encode, json.decode, json.null
local ws_parseUrl, ws_connect = websocket.parseUrl, websocket.connect
local format = string.format
local sleep = timer.sleep
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local concat = table.concat
local wrap = coroutine.wrap

local ID_DELAY = constants.ID_DELAY
local GATEWAY_VERSION = constants.GATEWAY_VERSION
local GATEWAY_DELAY = constants.GATEWAY_DELAY

local DISPATCH              = 0
local HEARTBEAT             = 1
local IDENTIFY              = 2
local STATUS_UPDATE         = 3
local VOICE_STATE_UPDATE    = 4
-- local VOICE_SERVER_PING = 5 -- TODO
local RESUME                = 6
local RECONNECT             = 7
local REQUEST_GUILD_MEMBERS = 8
local INVALID_SESSION       = 9
local HELLO                 = 10
local HEARTBEAT_ACK         = 11
local GUILD_SYNC            = 12

local TEXT   = 1
local BINARY = 2
local CLOSE  = 8

local ignore = {
	['CALL_DELETE'] = true,
	['CHANNEL_PINS_ACK'] = true,
	['GUILD_INTEGRATIONS_UPDATE'] = true,
	['MESSAGE_ACK'] = true,
	['PRESENCES_REPLACE'] = true,
	['USER_SETTINGS_UPDATE'] = true,
}

local Shard = require('class')('Shard', Emitter)

function Shard:__init(id, client)
	Emitter.__init(self)
	self._id = id
	self._client = client
	self._mutex = Mutex()
	self._sw = Stopwatch()
	self._backoff = 1000
end

for name in pairs(logLevel) do
	Shard[name] = function(self, fmt, ...)
		local client = self._client
		return client[name](client, format('Shard %i : %s', self._id, fmt), ...)
	end
end

function Shard:__tostring()
	return format('Shard: %i', self._id)
end

local function connect(url)
	local options = assert(ws_parseUrl(url))
	options.pathname = format('/?v=%i&encoding=json', GATEWAY_VERSION)
	return assert(ws_connect(options))
end

local function getReconnectTime(self, n, m)
	return self._backoff * (n + random() * (m - n))
end

local function incrementReconnectTime(self)
	self._backoff = min(self._backoff * 2, 30000)
end

local function decrementReconnectTime(self)
	self._backoff = max(self._backoff / 2, 1000)
end

function Shard:connect(url, token)

	local success, res, read, write = pcall(connect, url)

	if success then
		self._read = read
		self._write = write
		self._reconnect = nil
		self:info('Connected to %s', url)
		self:handlePayloads(token)
		self:info('Disconnected')
	else
		self:error('Could not connect to %s (%s)', url, res) -- TODO: get new url?
	end

	if self._reconnect then
		self:info('Reconnecting...')
		return self:connect(url, token)
	elseif self._reconnect == nil and self._client._options.autoReconnect then
		local backoff = getReconnectTime(self, 0.9, 1.1)
		incrementReconnectTime(self)
		self:info('Reconnecting after %i ms...', backoff)
		sleep(backoff)
		return self:connect(url, token)
	end

end

function Shard:disconnect(reconnect)
	if not self._write then return end
	self._reconnect = not not reconnect
	self:stopHeartbeat()
	self._write()
	self._read = nil
	self._write = nil
end

function Shard:handlePayloads(token)

	local client = self._client

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

		client:emit('raw', payload)
		payload = decode(payload, 1, null)

		local s = payload.s
		local t = payload.t
		local d = payload.d
		local op = payload.op

		if t ~= null then
			self:debug('WebSocket OP %s : %s : %s', op, t, s)
		else
			self:debug('WebSocket OP %s', op)
		end

		if op == DISPATCH then

			self._seq = s
			if not ignore[t] then
				EventHandler[t](d, client, self)
			end

		elseif op == HEARTBEAT then

			self:heartbeat()

		elseif op == RECONNECT then

			self:warning('Discord has requested a reconnection')
			self:disconnect(true)

		elseif op == INVALID_SESSION then

			if payload.d and self._session_id then
				self:info('Session invalidated, resuming...')
				self:resume(token)
			else
				self:info('Session invalidated, re-identifying...')
				sleep(random(1000, 5000))
				self:identify(token)
			end

		elseif op == HELLO then

			self:info('Received HELLO (%s)', concat(d._trace, ', '))
			self:startHeartbeat(d.heartbeat_interval)
			if self._session_id then
				self:resume(token)
			else
				self:identify(token)
			end

		elseif op == HEARTBEAT_ACK then

			self._waiting = nil
			client:emit('heartbeat', self._id, self._sw.milliseconds)

		elseif op then

			self:warning('Unhandled WebSocket payload OP %i', op)

		end

	end

end

local function loop(self)
	if self._waiting then
		self._waiting = nil
		self:warning('Previous heartbeat not acknowledged')
		return wrap(self.disconnect)(self, true)
	end
	decrementReconnectTime(self)
	wrap(self.heartbeat)(self)
end

function Shard:startHeartbeat(interval)
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = setInterval(interval, loop, self)
end

function Shard:stopHeartbeat()
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = nil
end

function Shard:identifyWait()
	if self:waitFor('READY', 1.5 * ID_DELAY) then
		return sleep(ID_DELAY)
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

function Shard:heartbeat()
	self._sw:reset()
	self._waiting = true
	return send(self, HEARTBEAT, self._seq or json.null)
end

function Shard:identify(token)

	local client = self._client
	local mutex = client._mutex
	local options = client._options

	mutex:lock()
	wrap(function()
		self:identifyWait()
		mutex:unlock()
	end)()

	self._seq = nil
	self._session_id = nil
	self._ready = false
	self._loading = {guilds = {}, chunks = {}, syncs = {}}

	return send(self, IDENTIFY, {
		token = token,
		properties = {
			['$os'] = jit.os,
			['$browser'] = 'Discordia',
			['$device'] = 'Discordia',
			['$referrer'] = '',
			['$referring_domain'] = '',
		},
		compress = options.compress,
		large_threshold = options.largeThreshold,
		shard = {self._id, client._total_shard_count},
		presence = next(client._presence) and client._presence,
	})

end

function Shard:resume(token)
	return send(self, RESUME, {
		token = token,
		session_id = self._session_id,
		seq = self._seq
	})
end

function Shard:requestGuildMembers(id)
	return send(self, REQUEST_GUILD_MEMBERS, {
		guild_id = id,
		query = '',
		limit = 0,
	})
end

function Shard:updateStatus(presence)
	return send(self, STATUS_UPDATE, presence)
end

function Shard:updateVoice(guild_id, channel_id, self_mute, self_deaf)
	return send(self, VOICE_STATE_UPDATE, {
		guild_id = guild_id,
		channel_id = channel_id or null,
		self_mute = self_mute or false,
		self_deaf = self_deaf or false,
	})
end

function Shard:syncGuilds(ids)
	return send(self, GUILD_SYNC, ids)
end

return Shard
