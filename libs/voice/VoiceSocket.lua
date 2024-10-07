local uv = require('uv')
local class = require('class')
local timer = require('timer')
local enums = require('enums')
local sodium = require('voice/sodium') or {}

local WebSocket = require('client/WebSocket')

local logLevel = assert(enums.logLevel)
local format = string.format
local setInterval, clearInterval = timer.setInterval, timer.clearInterval
local wrap = coroutine.wrap
local time = os.time
local unpack, pack = string.unpack, string.pack -- luacheck: ignore

local SUPPORTED_ENCRYPTION_MODES = { 'aead_xchacha20_poly1305_rtpsize' }
if sodium.aead_aes256_gcm then -- AEAD AES256-GCM is only available if the hardware supports it
	table.insert(SUPPORTED_ENCRYPTION_MODES, 1, 'aead_aes256_gcm_rtpsize')
end

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

local function checkMode(modes)
	for _, ENCRYPTION_MODE in ipairs(SUPPORTED_ENCRYPTION_MODES) do
		for _, mode in ipairs(modes) do
			if mode == ENCRYPTION_MODE then
				return mode
			end
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

function VoiceSocket:__init(state, connection, manager)
	WebSocket.__init(self, manager)
	self._state = state
	self._manager = manager
	self._client = manager._client
	self._connection = connection
	self._session_id = state.session_id
	self._seq_ack = -1
end

function VoiceSocket:handleDisconnect()
	-- TODO: reconnecting and resuming
	self._connection:_cleanup()
end

function VoiceSocket:handlePayload(payload)

	local manager = self._manager

	local d = payload.d
	local op = payload.op

	if payload.seq then
		self._seq_ack = payload.seq
	end

	self:debug('WebSocket OP %s', op)

	if op == HELLO then

		self:info('Received HELLO')
		self:startHeartbeat(d.heartbeat_interval)
		self:identify()

	elseif op == READY then

		self:info('Received READY')
		local mode = checkMode(d.modes)
		if mode then
			self:debug('Selected encryption mode %q', mode)
			self._mode = mode
			self._ssrc = d.ssrc
			self:handshake(d.ip, d.port)
		else
			self:error('No supported encryption mode available')
			self:disconnect()
		end

	elseif op == RESUMED then

		self:info('Received RESUMED')

	elseif op == DESCRIPTION then

		if d.mode == self._mode then
			self._connection:_prepare(d.secret_key, self)
		else
			self:error('%q encryption mode not available', self._mode)
			self:disconnect()
		end

	elseif op == HEARTBEAT_ACK then

		manager:emit('heartbeat', nil, self._sw.milliseconds) -- TODO: id

	elseif op == SPEAKING then

		return -- TODO

	elseif op == 12 or op == 13 then

		return -- ignore

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
	return self:_send(HEARTBEAT, {
		t = time(),
		seq_ack = self._seq_ack,
	})
end

function VoiceSocket:identify()
	local state = self._state
	return self:_send(IDENTIFY, {
		server_id = state.guild_id,
		user_id = state.user_id,
		session_id = state.session_id,
		token = state.token,
	}, true)
end

function VoiceSocket:resume()
	local state = self._state
	return self:_send(RESUME, {
		server_id = state.guild_id,
		session_id = state.session_id,
		token = state.token,
		seq_ack = self._seq_ack,
	})
end

function VoiceSocket:handshake(server_ip, server_port)
	local udp = uv.new_udp()
	self._udp = udp
	self._ip = server_ip
	self._port = server_port
	udp:recv_start(function(err, data)
		assert(not err, err)
		udp:recv_stop()
		local client_ip = unpack('xxxxxxxxz', data)
		local client_port = unpack('<I2', data, -2)
		return wrap(self.selectProtocol)(self, client_ip, client_port)
	end)
	local packet = pack('>I2I2I4c64H', 0x1, 70, self._ssrc, self._ip, self._port)
	return udp:send(packet, server_ip, server_port)
end

function VoiceSocket:selectProtocol(address, port)
	return self:_send(SELECT_PROTOCOL, {
		protocol = 'udp',
		data = {
			address = address,
			port = port,
			mode = self._mode,
		}
	})
end

function VoiceSocket:setSpeaking(speaking)
	return self:_send(SPEAKING, {
		speaking = speaking,
		delay = 0,
		ssrc = self._ssrc,
	})
end

return VoiceSocket
