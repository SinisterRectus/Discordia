local Channel = require('../Channel')

local VoiceChannel = class('VoiceChannel', Channel)

function VoiceChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	VoiceChannel.update(self, data)
end

function VoiceChannel:update(data)
	self.bitrate = data.bitrate
	self.userLimit = data.userLimit
end

return VoiceChannel
