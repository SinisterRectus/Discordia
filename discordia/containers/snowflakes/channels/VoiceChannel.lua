local Channel = require('../Channel')

local VoiceChannel = class('VoiceChannel', Channel)

function VoiceChannel:__init(data, parent)
	Channel.__init(self, data, parent)
end

return VoiceChannel
