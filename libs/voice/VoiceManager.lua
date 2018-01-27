local VoiceSocket = require('voice/VoiceSocket')
local Emitter = require('utils/Emitter')

local constants = require('constants')

local wrap = coroutine.wrap
local format = string.format

local GATEWAY_VERSION_VOICE = constants.GATEWAY_VERSION_VOICE

local VoiceManager = require('class')('VoiceManager', Emitter)

function VoiceManager:__init(client)
	Emitter.__init(self)
	self._client = client
	self._waiting = {}
end

function VoiceManager:loadOpus(path)
	self._opus = require('voice/opus')(path or 'opus')
end

function VoiceManager:loadSodium(path)
	self._sodium = require('voice/sodium')(path or 'sodium')
end

function VoiceManager:_prepareConnection(state, connection)
	if not self._opus then
		return self._client:error('Cannot connect to voice: libopus not loaded')
	end
	if not self._sodium then
		return self._client:error('Cannot connect to voice: libsodium not loaded')
	end
	local socket = VoiceSocket(state, connection, self)
	local url = 'wss://' .. state.endpoint:gsub(':%d*$', '')
	local path = format('/?v=%i', GATEWAY_VERSION_VOICE)
	return wrap(socket.connect)(socket, url, path)
end

return VoiceManager
