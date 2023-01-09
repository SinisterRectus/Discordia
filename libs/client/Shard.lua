local json = require('json')
local timer = require('timer')

local EventHandler = require('client/EventHandler')
local WebSocket = require('client/WebSocket')

local constants = require('constants')
local enums = require('enums')

local logLevel = assert(enums.logLevel)
local min, max, random = math.min, math.max, math.random
local null = json.null
local format = string.format
local sleep = timer.sleep
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local wrap = coroutine.wrap

local ID_DELAY = constants.ID_DELAY

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

local ignore = {
	['CALL_DELETE'] = true,
	['CHANNEL_PINS_ACK'] = true,
	['GUILD_INTEGRATIONS_UPDATE'] = true,
	['MESSAGE_ACK'] = true,
	['PRESENCES_REPLACE'] = true,
	['USER_SETTINGS_UPDATE'] = true,
	['USER_GUILD_SETTINGS_UPDATE'] = true,
	['SESSIONS_REPLACE'] = true,
	['INVITE_CREATE'] = true,
	['INVITE_DELETE'] = true,
	['INTEGRATION_CREATE'] = true,
	['INTEGRATION_UPDATE'] = true,
	['INTEGRATION_DELETE'] = true,
	['EMBEDDED_ACTIVITY_UPDATE'] = true,
	['GIFT_CODE_UPDATE'] = true,
	['GUILD_JOIN_REQUEST_UPDATE'] = true,
	['GUILD_JOIN_REQUEST_DELETE'] = true,
	['APPLICATION_COMMAND_PERMISSIONS_UPDATE'] = true,
}

local Shard = require('class')('Shard', WebSocket)

function Shard:__init(id, client)
	WebSocket.__init(self, client)
	self._id = id
	self._client = client
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

local function getReconnectTime(self, n, m)
	return self._backoff * (n + random() * (m - n))
end

local function incrementReconnectTime(self)
	self._backoff = min(self._backoff * 2, 60000)
end

local function decrementReconnectTime(self)
	self._backoff = max(self._backoff / 2, 1000)
end

function Shard:handleDisconnect(url, path)
	self._client:emit('shardDisconnect', self._id)
	if self._reconnect then
		self:info('Reconnecting...')
		return self:connect(url, path)
	elseif self._reconnect == nil and self._client._options.autoReconnect then
		local backoff = getReconnectTime(self, 0.9, 1.1)
		incrementReconnectTime(self)
		self:info('Reconnecting after %i ms...', backoff)
		sleep(backoff)
		return self:connect(url, path)
	end
end

function Shard:handlePayload(payload)

	local client = self._client

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

		self:info('Discord has requested a reconnection')
		self:disconnect(true)

	elseif op == INVALID_SESSION then

		if payload.d and self._session_id then
			self:info('Session invalidated, resuming...')
			self:resume()
		else
			self:info('Session invalidated, re-identifying...')
			sleep(random(1000, 5000))
			self:identify()
		end

	elseif op == HELLO then

		self:info('Received HELLO')
		self:startHeartbeat(d.heartbeat_interval)
		if self._session_id then
			self:resume()
		else
			self:identify()
		end

	elseif op == HEARTBEAT_ACK then

		client:emit('heartbeat', self._id, self._sw.milliseconds)

	elseif op then

		self:warning('Unhandled WebSocket payload OP %i', op)

	end

end

local function loop(self)
	decrementReconnectTime(self)
	return wrap(self.heartbeat)(self)
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

function Shard:heartbeat()
	self._sw:reset()
	return self:_send(HEARTBEAT, self._seq or json.null)
end

function Shard:identify()

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

	return self:_send(IDENTIFY, {
		token = client._token,
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
		intents = client._intents,
	}, true)

end

function Shard:resume()
	return self:_send(RESUME, {
		token = self._client._token,
		session_id = self._session_id,
		seq = self._seq
	})
end

function Shard:requestGuildMembers(id)
	return self:_send(REQUEST_GUILD_MEMBERS, {
		guild_id = id,
		query = '',
		limit = 0,
	})
end

function Shard:updateStatus(presence)
	return self:_send(STATUS_UPDATE, presence)
end

function Shard:updateVoice(guild_id, channel_id, self_mute, self_deaf)
	return self:_send(VOICE_STATE_UPDATE, {
		guild_id = guild_id,
		channel_id = channel_id or null,
		self_mute = self_mute or false,
		self_deaf = self_deaf or false,
	})
end

function Shard:syncGuilds(ids)
	return self:_send(GUILD_SYNC, ids)
end

return Shard
