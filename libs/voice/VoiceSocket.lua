local uv = require('uv')
local class = require('class')
local timer = require('timer')
local enums = require('enums')
local sodium = require('voice/sodium') or {}
local ok, dave = pcall(require, 'litdave')
if not ok then
	dave = {}
end

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

local IDENTIFY                       = 0
local SELECT_PROTOCOL                = 1
local READY                          = 2
local HEARTBEAT                      = 3
local DESCRIPTION                    = 4
local SPEAKING                       = 5
local HEARTBEAT_ACK                  = 6
local RESUME                         = 7
local HELLO                          = 8
local RESUMED                        = 9
local CLIENTS_CONNECT                = 11
local CLIENT_DISCONNECT              = 13
local DAVE_PREPARE_TRANSITION        = 21
local DAVE_EXECUTE_TRANSITION        = 22
local DAVE_TRANSITION_READY          = 23
local DAVE_PREPARE_EPOCH             = 24
local MLS_EXTERNAL_SENDER            = 25
local MLS_KEY_PACKAGE                = 26
local MLS_PROPOSALS                  = 27
local MLS_COMMIT_WELCOME             = 28
local MLS_ANNOUNCE_COMMIT_TRANSITION = 29
local MLS_WELCOME                    = 30
local MLS_INVALID_COMMIT_WELCOME     = 31

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
	self._voice = true
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

			self._connection._dave_encryptor:assignSsrcToCodec(d.ssrc, dave.enums.codec.OPUS)
		else
			self:error('No supported encryption mode available')
			self:disconnect()
		end

	elseif op == RESUMED then

		self:info('Received RESUMED')

	elseif op == DESCRIPTION then

		if d.dave_protocol_version then -- if Discord changes version of (or disables) E2EE
			self._state.max_dave_protocol_version = d.dave_protocol_version
			self._connection._dave_protocol_version = d.dave_protocol_version
			self._connection._dave_session:setProtocolVersion(d.dave_protocol_version)
		end

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

	elseif op == 12 or op == 18 or op == 20 then

		return -- ignore

	elseif op == CLIENTS_CONNECT then

		if d.user_ids then
			for _, user_id in pairs(d.user_ids) do
				self._connection._dave_session:addRecognizedUser(user_id)
			end
		end

	elseif op == CLIENT_DISCONNECT then

		self._connection._dave_session:removeRecognizedUser(d.user_id)

	elseif op == DAVE_PREPARE_TRANSITION then

		self._connection._dave_protocol_version_pending = d.protocol_version
		self:sendTransitionReady(d.transition_id)

	elseif op == DAVE_EXECUTE_TRANSITION then

		if self._connection._dave_protocol_version_pending then
			self._connection._dave_protocol_version = self._connection._dave_protocol_version_pending
			self._connection._dave_protocol_version_pending = nil
		end

		self._connection._dave_session:setProtocolVersion(self._connection._dave_protocol_version)
		self._connection._dave_session:reset()
		self._connection._dave_encryptor:setKeyRatchet(self._connection._dave_session:getKeyRatchet(self._client.user.id))

		self._connection._dave_ready = true

	elseif op == DAVE_PREPARE_EPOCH then

		if d.epoch == 1 then
			self._connection._dave_ready = false
			self._connection._dave_protocol_version = d.protocol_version
			self._connection._dave_session:init(self._connection._dave_protocol_version, self._connection._channel.id, self._client.user.id)
			self:setKeyPackage()
		end

	elseif op == MLS_EXTERNAL_SENDER then

		self._connection._dave_session:setExternalSender(payload.binary)
		self:setKeyPackage()

	elseif op == MLS_PROPOSALS then

		local welcome_result = self._connection._dave_session:processProposals(payload.binary)
		if welcome_result then
			self:commitWelcome(welcome_result)
		end

	elseif op == MLS_ANNOUNCE_COMMIT_TRANSITION then

		local transition_id = tonumber(string.unpack(">I2", payload.binary))
		local commit_result = self._connection._dave_session:processCommit(payload.binary:sub(3))

		if commit_result and not commit_result.isFailed() then
			if transition_id == 0 then
				self._connection._dave_encryptor:setKeyRatchet(self._connection._dave_session:getKeyRatchet(self._client.user.id))
				self._connection._dave_ready = true
			else
				self:sendTransitionReady(transition_id)
			end
		else
			self:handleInvalidCommitWelcome(transition_id)
		end

	elseif op == MLS_WELCOME then

		local transition_id = tonumber(string.unpack(">I2", payload.binary))
		local welcome_result = self._connection._dave_session:processWelcome(payload.binary:sub(3))

		if welcome_result then
			if transition_id == 0 then
				self._connection._dave_encryptor:setKeyRatchet(self._connection._dave_session:getKeyRatchet(self._client.user.id))
				self._connection._dave_ready = true
			else
				self:sendTransitionReady(transition_id)
			end
		else
			self:handleInvalidCommitWelcome(transition_id)
		end

	elseif op then

		self:warning('Unhandled WebSocket payload OP %i', op)

	end

end

function VoiceSocket:handleInvalidCommitWelcome(transition_id)
	self:sendInvalidCommitWelcome(transition_id)
	self._connection._dave_session:init(self._connection._dave_protocol_version, self._connection._channel.id, self._client.user.id)
	self:setKeyPackage()
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
	if state.max_dave_protocol_version == nil then -- if not present yet
		state.max_dave_protocol_version = dave.maxSupportedProtocolVersion
	end

	return self:_send(IDENTIFY, {
		server_id = state.guild_id,
		user_id = state.user_id,
		session_id = state.session_id,
		token = state.token,
		max_dave_protocol_version = state.max_dave_protocol_version
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

function VoiceSocket:setKeyPackage()
	return self:_send(MLS_KEY_PACKAGE, self._connection._dave_session:getMarshalledKeyPackage())
end

function VoiceSocket:commitWelcome(welcome_result)
	return self:_send(MLS_COMMIT_WELCOME, welcome_result)
end

function VoiceSocket:sendTransitionReady(transition_id)
	return self:_send(DAVE_TRANSITION_READY, {
		transition_id = transition_id
	})
end

function VoiceSocket:sendInvalidCommitWelcome(transition_id)
	return self:_send(MLS_INVALID_COMMIT_WELCOME, {
		transition_id = transition_id
	})
end

return VoiceSocket
