local VoiceSocket = require('voice/VoiceSocket')
local Emitter = require('utils/Emitter')

local wrap = coroutine.wrap

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
	local endpoint = state.endpoint:gsub(':%d*$', '')
	wrap(socket.connect)(socket, 'wss://' .. endpoint)
end

return VoiceManager
