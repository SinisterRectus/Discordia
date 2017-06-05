local Channel = require('containers/abstract/Channel')

local GuildVoiceChannel = require('class')('GuildVoiceChannel', Channel)

function GuildVoiceChannel:__init(data, parent)
	Channel.__init(self, data, parent)
end

return GuildVoiceChannel
