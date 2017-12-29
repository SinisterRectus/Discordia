local VoiceSocket = require('voice/VoiceSocket')
local Emitter = require('utils/Emitter')
local enums = require('enums')

local logLevel = enums.logLevel
local format = string.format
local wrap = coroutine.wrap

local VoiceManager = require('class')('VoiceManager', Emitter)

for name in pairs(logLevel) do
	VoiceManager[name] = function(self, fmt, ...)
		local client = self._client
		return client[name](client, format('Voice : %s', fmt), ...)
	end
end

function VoiceManager:__init(client)
	Emitter.__init(self)
	self._client = client
end

function VoiceManager:_createVoiceConnection(d, state)
	local socket = VoiceSocket(d, state.session_id, self)
	local endpoint = d.endpoint:gsub(':%d*', '')
	local url = 'wss://' .. endpoint
	wrap(socket.connect)(socket, url)
end

return VoiceManager
