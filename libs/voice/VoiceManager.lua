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

function VoiceManager:loadOpus(path)
	local opus, err = require('voice/opus')(path or 'opus')
	if opus then
		self._opus = opus
	else
		return self:error(err)
	end
end

function VoiceManager:loadSodium(path)
	local sodium, err = require('voice/sodium')(path or 'sodium')
	if sodium then
		self._sodium = sodium
	else
		return self:error(err)
	end
end

function VoiceManager:_createVoiceConnection(d, state)
	local socket = VoiceSocket(d, state.session_id, self)
	if not self._opus then
		return self:error('Cannot connect: libopus not loaded')
	end
	if not self._sodium then
		return self:error('Cannot connect: libsodium not loaded')
	end
	local endpoint = d.endpoint:gsub(':%d*', '')
	local url = 'wss://' .. endpoint
	wrap(socket.connect)(socket, url)
end

return VoiceManager
