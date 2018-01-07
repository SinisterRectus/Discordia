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
end

function VoiceManager:loadOpus(path)
	local opus, err = require('voice/opus')(path or 'opus')
	if opus then
		self._opus = opus
	else
		return self._client:error(err)
	end
end

function VoiceManager:loadSodium(path)
	local sodium, err = require('voice/sodium')(path or 'sodium')
	if sodium then
		self._sodium = sodium
	else
		return self._client:error(err)
	end
end

function VoiceManager:_createVoiceConnection(state)
	if not self._opus then
		return self._client:error('Cannot connect to voice: libopus not loaded')
	end
	if not self._sodium then
		return self._client:error('Cannot connect to voice: libsodium not loaded')
	end
	local socket = VoiceSocket(state, self)
	local url = 'wss://' .. state.endpoint:gsub(':%d*$', '')
	local path = format('/?v=%i', GATEWAY_VERSION_VOICE)
	wrap(socket.connect)(socket, url, path)
end

return VoiceManager
