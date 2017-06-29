local GuildChannel = require('containers/abstract/GuildChannel')

local GuildVoiceChannel = require('class')('GuildVoiceChannel', GuildChannel)
local get = GuildVoiceChannel.__getters

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

function get.bitrate(self)
	return self._bitrate
end

function get.userLimit(self)
	return self._user_limit
end

return GuildVoiceChannel
