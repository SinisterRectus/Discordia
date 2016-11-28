local Emitter = require('../utils/Emitter')
local VoiceSocket = require('./VoiceSocket')

local VoiceClient = class('VoiceClient', Emitter)

function VoiceClient:__init()
	Emitter.__init(self)
	self._voice_socket = VoiceSocket(self)
end

function VoiceClient:joinChannel(channel, selfMute, selfDeaf)
	local client = channel.client
	client._voice_client = self
	return client._socket:joinVoiceChannel(channel._parent._id, channel._id, selfMute, selfDeaf)
end

return VoiceClient
