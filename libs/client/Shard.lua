local json = require('json')
local timer = require('timer')
local miniz = require('miniz')
local websocket = require('coro-websocket')

local Emitter = require('utils/Emitter')
local Mutex = require('utils/Mutex')
local Stopwatch = require('utils/Stopwatch')
local EventHandler = require('client/EventHandler')

local constants = require('constants')

local inflate = miniz.inflate
local min, max, random = math.min, math.max, math.random
local encode, decode = json.encode, json.decode
local parseUrl, connect = websocket.parseUrl, websocket.connect
local format = string.format
local sleep = timer.sleep
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local concat = table.concat
local wrap, yield = coroutine.wrap, coroutine.yield

local ID_DELAY = constants.ID_DELAY
local GATEWAY_VERSION = constants.GATEWAY_VERSION
local GATEWAY_DELAY = constants.GATEWAY_DELAY

local DISPATCH              = 0
local HEARTBEAT             = 1
local IDENTIFY              = 2
-- local STATUS_UPDATE = 3 -- TODO
-- local VOICE_STATE_UPDATE = 4 -- TODO
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
	['MESSAGE_ACK'] = true,
	['CHANNEL_PINS_ACK'] = true,
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

for _, name in ipairs({'error', 'warning', 'info', 'debug'}) do
	Shard[name] = function(self, fmt, ...)
		local client = self._client
		return client[name](client, format('Shard %i : %s', self._id, fmt), ...)
	end
end

function Shard:__tostring()
	return format('Shard: %i', self._id)
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

	local options = parseUrl(url)
	options.pathname = format('/?v=%i&encoding=json', GATEWAY_VERSION) -- TODO: etf

	local res, read, write = connect(options) -- TODO: pcall?

	if res and res.code == 101 then
		self._read = read
		self._write = write
		self._reconnect = nil
		self:info('Connected to %s', url)
		self:handlePayloads(token)
		self:info('Disconnected')
	else
		self:error('Could not connect to %s (%s)', url, read)
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

function Shard:disconnect(reconnect) -- TODO: coro-websocket PR
	if not self._write then return end
	self._reconnect = not not reconnect
	self:stopHeartbeat()
	self._write() -- is there a better way to close?
	self._read = nil
	self._write = nil
end

-- TODO: check for failed heartbeats / out of sequence events

function Shard:handlePayloads(token)

	local client = self._client

	for message in self._read do

		local opcode = message.opcode
		local payload = message.payload

		if opcode == TEXT then

			payload = decode(payload)

		elseif opcode == BINARY then

			payload = decode(inflate(payload, 15))

		elseif opcode == CLOSE then -- TODO: coro-websocket PR

			local code, i = ('>H'):unpack(payload)
			self:warning('%i - %s', code, payload:sub(i))

		end

		local s = payload.s
		local t = payload.t
		local d = payload.d
		local op = payload.op

		if op == DISPATCH then
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

			self:disconnect(true)

		elseif op == INVALID_SESSION then

			if payload.d then
				self:info('Session invalidated, resuming...')
				sleep(random(1000, 2000))
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

			client:emit('heartbeat', self._id, self._sw.milliseconds)

		elseif op then

			self:warning('Unhandled WebSocket OP %i', op)

		end

	end

end

local function loop(self)
	while true do
		decrementReconnectTime(self)
		self:heartbeat()
		yield()
	end
end

function Shard:startHeartbeat(interval)
	if self._heartbeat then
		clearInterval(self._heartbeat)
	end
	self._heartbeat = setInterval(interval, wrap(loop), self)
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
	-- TODO: pcall / check for _write / wrap?
	self._mutex:lock()
	self._write {opcode = TEXT, payload = encode {op = op, d = d}}
	self._mutex:unlockAfter(GATEWAY_DELAY)
end

function Shard:heartbeat()
	self._sw:restart()
	return send(self, HEARTBEAT, self._seq)
end

function Shard:identify(token)

	local client = self._client
	local mutex = client._mutex

	mutex:lock()
	wrap(function() -- TODO: check what happens if this isn't a coroutine
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
		large_threshold = client._options.largeThreshold,
		compress = client._options.compress,
		shard = {self._id, client._shard_count},
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

function Shard:syncGuilds(ids)
	return send(self, GUILD_SYNC, ids)
end

return Shard
