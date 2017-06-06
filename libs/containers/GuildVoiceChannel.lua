local GuildChannel = require('containers/abstract/GuildChannel')

local GuildVoiceChannel = require('class')('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

return GuildVoiceChannel
