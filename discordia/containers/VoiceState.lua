local Container = require('../utils/Container')

local VoiceState, accessors = class('VoiceState', Container)

accessors.guild = function(self) return self.parent end

function VoiceState:__init(data, parent)
	Container.__init(self, parent)
	self.userId = data.userId
	self.sessionId = data.session_id
end

function VoiceState:update(data)
	self.channelId = data.channel_id
	self.mute = data.mute
	self.deaf = data.deaf
	self.selfMute = data.self_mute
	self.selfDeaf = data.self_dead
	self.suppress = data.suppress
end

function VoiceState:__tostring()
	return string.format('%s: %s', self.__name, self.sessionId)
end

function VoiceState:__eq(other)
	return self.__class == other.__class and self.sessionId == other.sessionId
end

return VoiceState
