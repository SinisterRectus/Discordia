local VoiceState = class('VoiceState')

function VoiceState:__init(data, server)

	self.client = server.client
	self.server = server

	self.userId = data.userId -- string
	self.sessionId = data.sessionId -- string
	self.channelId = data.channelId -- string

	self:_update(data)

end

function VoiceState:__tostring()
	return string.format('%s: %s', self.__name, self.sessionId)
end

function VoiceState:_update(data)
	self.mute = data.mute
	self.deaf = data.deaf
	self.selfDeaf = data.selfDeaf
	self.selfMute = data.selfMute
	self.suppress = data.suppress
end

return VoiceState
