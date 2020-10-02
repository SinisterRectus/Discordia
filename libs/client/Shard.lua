local json = require('json')
local miniz = require('miniz')
local timer = require('timer')
local ws = require('coro-websocket')

local class = require('../class')
local Mutex = require('../utils/Mutex')
local Emitter = require('../utils/Emitter')
local EventHandler = require('./EventHandler')
local Stopwatch = require('../utils/Stopwatch')

local wrap = coroutine.wrap
local format = string.format
local inflate = miniz.inflate
local min, max = math.min, math.max
local encode, decode, null = json.encode, json.decode, json.null
local sleep, setInterval, clearInterval = timer.sleep, timer.setInterval, timer.clearInterval

local SEND_DELAY = 500
local IDENTIFY_DELAY = 5000
local MIN_RECONNECT_DELAY = 1000
local MAX_RECONNECT_DELAY = 32000

local TEXT   = 1
local BINARY = 2
local CLOSE  = 8

local DISPATCH              = 0
local HEARTBEAT             = 1
local IDENTIFY              = 2
local PRESENCE_UPDATE       = 3
local VOICE_STATE_UPDATE    = 4
local RESUME                = 6
local RECONNECT             = 7
local REQUEST_GUILD_MEMBERS = 8
local INVALID_SESSION       = 9
local HELLO                 = 10
local HEARTBEAT_ACK         = 11

local fatalClose = {
	[4004] = true, -- authentication failed
	[4010] = true, -- invalid shard
	[4011] = true, -- sharding required
	[4012] = true, -- invalid api version
	[4013] = true, -- invalid intent(s)
	[4014] = true, -- disallowed intent(s)
}

local sessionless = {
	[IDENTIFY] = true,
	[HEARTBEAT] = true,
}

local priority = {
	[RESUME] = true,
	[IDENTIFY] = true,
	[HEARTBEAT] = true,
}

local function connect(url, path)
	local options = assert(ws.parseUrl(url))
	options.pathname = path -- coro-ws inconsistency
	return assert(ws.connect(options))
end

local globalMutex = Mutex()

local Shard, get = class('Shard', Emitter)

function Shard:__init(id, client)
	Emitter.__init(self)
	self._id = id
	self._client = client
	self._sendMutex = Mutex()
	self._reconnectDelay = MIN_RECONNECT_DELAY
	self._events = 0
	self._commands = 0
	self._rx = 0
	self._tx = 0
	self._seq = nil
	self._write = nil
	self._ready = nil
	self._loading = nil
	self._sessionId = nil
	self._heartbeat = nil
	self._reconnect = nil
end

function Shard:__tostring()
	return format('Shard: %i', self._id)
end

function Shard:log(level, msg, ...)
	msg = format(msg, ...)
	self._client:log(level, 'Shard %i: %s', self._id, msg)
	return msg
end

function Shard:readySession(data)
	self._sessionId = data.session_id
	self._loading = {}
	for _, guild in pairs(data.guilds) do
		self._loading[guild.id] = guild.unavailable
	end
	self:emit('READY')
	self:log('info', 'Session ready')
	self._client:emit('sessionReady', self._id)
end

function Shard:resumeSession()
	self:emit('RESUMED')
	self:log('info', 'Session resumed')
	self._client:emit('sessionResumed', self._id)
end

function Shard:guildIsLoading(guildId)
	return self._loading and self._loading[guildId]
end

function Shard:setGuildReady(guildId)
	if self._loading then
		self._loading[guildId] = nil
	end
end

function Shard:checkReady()
	if self._loading and not next(self._loading) then
		self._loading = nil
		self._ready = true
		self._client:emit('shardReady', self._id)
		if self._client.ready then
			return self._client:emit('ready')
		end
	end
end

function Shard:identifyWait()
	if self:waitFor('READY', IDENTIFY_DELAY) then
		return sleep(IDENTIFY_DELAY)
	end
end

function Shard:connect(url, path)

	local success, res, read, write = pcall(connect, url, path)

	if success then
		self._write = write
		self._reconnect = nil
		self:log('info', 'Connected to %s', url)
		for message in read do
			self:parseMessage(message)
		end
		self:stopHeartbeat()
		self._write = nil
		self:log('info', 'Disconnected')
	else
		self:log('error', 'Could not connect to %s (%s)', url, res)
		url = self.client:getGatewayURL() or url
	end

	if self._reconnect ~= false then
		local delay = self:incrementReconnectDelay()
		self:log('info', 'Reconnecting after %i ms...', delay)
		sleep(delay)
		return self:connect(url, path)
	end

end

function Shard:incrementReconnectDelay()
	local delay = self._reconnectDelay
	self._reconnectDelay = min(delay * 2, MAX_RECONNECT_DELAY)
	return delay
end

function Shard:decrementReconnectDelay()
	local delay = self._reconnectDelay
	self._reconnectDelay = max(delay / 2, MIN_RECONNECT_DELAY)
	return delay
end

function Shard:disconnect(reconnect)
	self._reconnect = not not reconnect
	return self._write and self._write {
		opcode = CLOSE,
		payload = string.pack('>I2', reconnect and 4000 or 1000)
	}
end

function Shard:parseMessage(message)

	local opcode = message.opcode
	local payload = message.payload

	if opcode == TEXT then

		return self:handlePayload(payload)

	elseif opcode == BINARY then

		payload = inflate(payload, 1)
		return self:handlePayload(payload)

	elseif opcode == CLOSE then

		local code, msg = string.unpack('>I2z', payload)
		msg = #msg > 0 and msg or 'Unknown reason'
		if fatalClose[code] then
			self._reconnect = false
			return self:log('critical', 'Connection closed : %i - %s', code, msg)
		else
			self._reconnect = true
			return self:log('warning', 'Connection closed : %i - %s', code, msg)
		end

	end

end

function Shard:handlePayload(payload)

	self._rx = self._rx + #payload
	self._events = self._events + 1
	self._client:emit('gatewayEvent', self._id, payload)

	payload = decode(payload)

	local op = payload.op

	if op == DISPATCH then
		local s = payload.s
		local t = payload.t
		self._seq = s
		self:log('debug', 'Received OP %s : %s : %s', op, t, s)
		return EventHandler[t](payload.d, self._client, self)
	end

	self:log('debug', 'Received OP %s', op)

	if op == HEARTBEAT then

		self:heartbeat()

	elseif op == RECONNECT then

		self:log('info', 'Discord has requested a reconnection')
		self:disconnect(true)

	elseif op == INVALID_SESSION then

		if payload.d == true and self._sessionId then
			self:log('info', 'Session invalidated, attempting to resume...')
			self:resume()
		else
			self:log('info', 'Session invalidated, attempting to reidentify...')
			self:identify()
		end

	elseif op == HELLO then

		self:startHeartbeat(payload.d.heartbeat_interval)
		if self._sessionId then
			self:log('info', 'Resuming session...')
			self:resume()
		else
			self:log('info', 'Starting session...')
			self:identify()
		end

	elseif op == HEARTBEAT_ACK then

		self._client:emit('heartbeat', self._id)

	elseif op then

		self:log('warning', 'Unhandled gateway payload OP %i', op)

	end

end

function Shard:startHeartbeat(interval)
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = setInterval(interval, function()
		self:decrementReconnectDelay()
		return wrap(self.heartbeat)(self)
	end)
end

function Shard:stopHeartbeat()
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = nil
end

function Shard:send(op, d)

	local sessionId = self._sessionId
	self._sendMutex:lock(priority[op])

	local payload, success, err
	if not self._write then
		err = 'Not connected'
	elseif not sessionless[op] and not self._sessionId then
		err = 'Not authenticated'
	elseif not sessionless[op] and sessionId ~= self._sessionId then
		err = 'Expired session'
	else
		payload = encode {op = op, d = d}
		success, err = self._write {opcode = TEXT, payload = payload}
	end

	self._sendMutex:unlockAfter(SEND_DELAY)

	if success then
		self._tx = self._tx + #payload
		self._commands = self._commands + 1
		self._client:emit('gatewayCommand', self._id, payload)
		return success, self:log('debug', 'Sent OP %s', op)
	else
		return success, self:log('error', 'Could not send OP %s : %s', op, err)
	end

end

function Shard:heartbeat()
	return self:send(HEARTBEAT, self._seq or null)
end

function Shard:identify()

	self._seq = nil
	self._ready = nil
	self._sessionId = nil

	globalMutex:lock()
	wrap(function()
		self:identifyWait()
		globalMutex:unlock()
	end)()

	local client = self._client

	return self:send(IDENTIFY, {
		token = client.token,
		properties = {
			['$os'] = jit.os,
			['$browser'] = 'Discordia',
			['$device'] = 'Discordia',
		},
		intents = client.gatewayIntents,
		compress = client.payloadCompression,
		shard = {self._id, client.totalShardCount},
		presence = {
			status = client.status or null,
			game = client.activity or null,
			since = null, afk = null,
		},
	})

end

function Shard:resume()
	return self:send(RESUME, {
		token = self._client.token,
		session_id = self._sessionId,
		seq = self._seq,
	})
end

function Shard:updatePresence(status, activity)
	return self:send(PRESENCE_UPDATE, {
		status = status or null,
		game = activity or null,
		since = null, afk = null,
	})
end

function get:id()
	return self._id
end

function get:ready()
	return self._ready
end

function get:eventsReceived()
	return self._events
end

function get:commandsTransmitted()
	return self._commands
end

function get:bytesReceived()
	return self._rx
end

function get:bytesTransmitted()
	return self._tx
end

return Shard
