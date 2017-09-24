local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')

local GuildVoiceChannel, get = require('class')('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

function GuildVoiceChannel:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate or json.null})
end

function GuildVoiceChannel:setUserLimit(user_limit)
	return self:_modify({user_limit = user_limit or json.null})
end

function get.bitrate(self)
	return self._bitrate
end

function get.userLimit(self)
	return self._user_limit
end

return GuildVoiceChannel
