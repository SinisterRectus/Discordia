local Object = require('./object')

class('VoiceState', Object)

function VoiceState:__init(data, server)

	Object.__init(self, data.sessionId, server.client)

	self.server = server

	self.userId = data.userId -- string
	self.sessionId = data.sessionId -- string
	self.channelId = data.channelId -- string

	self:update(data)

end

function VoiceState:update(data)
	self.mute = data.mute
	self.deaf = data.deaf
	self.selfDeaf = data.selfDeaf
	self.selfMute = data.selfMute
	self.suppress = data.suppress
end

return VoiceState
