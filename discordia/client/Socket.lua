local jit = require('jit')
local json = require('json')
local timer = require('timer')
local miniz = require('miniz')
local websocket = require('coro-websocket')
local EventHandler = require('./EventHandler')
local Stopwatch = require('../utils/Stopwatch')

local format = string.format
local inflate = miniz.inflate
local min, max = math.min, math.max
local encode, decode = json.encode, json.decode
local wrap, yield = coroutine.wrap, coroutine.yield
local parseUrl, connect = websocket.parseUrl, websocket.connect
local sleep, setInterval, clearInterval = timer.sleep, timer.setInterval, timer.clearInterval

local ignore = {
	['MESSAGE_ACK'] = true,
	['CHANNEL_PINS_ACK'] = true,
	['CHANNEL_PINS_UPDATE'] = true,
	['GUILD_INTEGRATIONS_UPDATE'] = true,
	['MESSAGE_REACTION_REMOVE_ALL'] = true,
	['WEBHOOKS_UPDATE'] = true,
}

local Socket = class('Socket')

function Socket:__init(id, gateway, client)
	self._id = id
	self._gateway = gateway
	self._client = client
	self._backoff = 1000
	self._stopwatch = Stopwatch()
	self._loading = {guilds = {}, chunks = {}, syncs = {}}
end

function Socket:__tostring()
	return format('Socket: %i', self._id)
end

local function incrementReconnectTime(self)
	self._backoff = min(self._backoff * 2, 64000)
end

local function decrementReconnectTime(self)
	self._backoff = max(self._backoff / 2, 1000)
end

function Socket:connect()
	local options = parseUrl(self._gateway .. '/')
	options.pathname = options.pathname .. '?v=5'
	self._res, self._read, self._write = connect(options)
	self._connected = self._res and self._res.code == 101
	return self._connected
end

function Socket:reconnect()
	if self._connected then self:disconnect() end
	return self:connect()
end

function Socket:disconnect()
	if not self._connected then return end
	self._connected = false
	self:stopHeartbeat()
	self._write()
	self._res, self._read, self._write = nil, nil, nil
end

local function handleUnexpectedDisconnect(self, token)
	self._client:warning(format('Attemping to reconnect after %i ms...', self._backoff))
	sleep(self._backoff)
	incrementReconnectTime(self)
	if not self:reconnect() then
		return handleUnexpectedDisconnect(self, token)
	end
	self._client:_parseToken(token)
	return self:handlePayloads(token)
end

function Socket:handlePayloads(token)

	local client = self._client

	for data in self._read do

		local str = data.opcode == 2 and inflate(data.payload, 15) or data.payload
		local payload = decode(str)

		client:emit('raw', payload, str)

		local op = payload.op

		if op == 0 then
			self._seq = payload.s
			if not ignore[payload.t] then
				local handler = EventHandler[payload.t]
				if handler then
					handler(payload.d, client, self)
				else
					client:warning('Unhandled event: ' .. payload.t)
				end
			end
		elseif op == 1 then
			self:heartbeat()
		elseif op == 7 then
			self:reconnect()
		elseif op == 9 then
			client:warning('Invalid session, attempting to re-identify...')
			self:identify(token)
		elseif op == 10 then
			self:startHeartbeat(payload.d.heartbeat_interval)
			if self._session_id then
				self:resume(token)
			else
				self:identify(token)
			end
		elseif op == 11 then
			client:emit('heartbeat', self._seq, self._stopwatch.milliseconds, self._id)
		else
			client:warning('Unhandled payload: ' .. op)
		end

	end

	if self._connected then
		self._connected = false
		self:stopHeartbeat()
		client:warning(format('Shard %i disconnected unexpectedly', self._id))
		if client._options.autoReconnect then
			return handleUnexpectedDisconnect(self, token)
		end
	end

end

function Socket:startHeartbeat(interval)
	if self._heartbeatInterval then clearInterval(self._heartbeatInterval) end
	self._heartbeatInterval = setInterval(interval, wrap(function()
		while true do
			decrementReconnectTime(self)
			yield(self:heartbeat())
		end
	end))
end

function Socket:stopHeartbeat()
	if not self._heartbeatInterval then return end
	clearInterval(self._heartbeatInterval)
	self._heartbeatInterval = nil
end

local function send(self, op, d)
	return wrap(self._write)({
		opcode = 1,
		payload = encode({op = op, d = d})
	})
end

function Socket:heartbeat()
	self._stopwatch:restart()
	return send(self, 1, self._seq)
end

function Socket:identify(token)
	self._ready = false
	local client = self._client
	return send(self, 2, {
		token = token,
		properties = {
			['$os'] = jit.os,
			['$browser'] = 'Discordia',
			['$device'] = 'Discordia',
			['$referrer'] = '',
			['$referring_domain'] = ''
		},
		large_threshold = client._options.largeThreshold,
		compress = client._options.compress,
		shard = {self._id, client._shard_count},
	})
end

function Socket:statusUpdate(idleSince, gameName)
	return send(self, 3, {
		idle_since = idleSince or json.null,
		game = {name = gameName or json.null},
	})
end

function Socket:joinVoiceChannel(guild_id, channel_id, self_mute, self_deaf)
	return send(self, 4, {
		guild_id = guild_id or json.null,
		channel_id = channel_id or json.null,
		self_mute = self_mute or false,
		self_deaf = self_deaf or false,
	})
end

function Socket:resume(token)
	return send(self, 6, {
		token = token,
		session_id = self._session_id,
		seq = self._seq
	})
end

function Socket:requestGuildMembers(guild_id)
	return send(self, 8, {
		guild_id = guild_id,
		query = '',
		limit = 0
	})
end

function Socket:syncGuilds(guild_ids)
	return send(self, 12, guild_ids)
end

return Socket
