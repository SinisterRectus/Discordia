local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')

local GuildVoiceChannel, get = require('class')('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

--[[
@method setBitrate
@param bitrate: number
@ret boolean
]]
function GuildVoiceChannel:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate or json.null})
end

--[[
@method setUserLimit
@param userLimit: number
@ret boolean
]]
function GuildVoiceChannel:setUserLimit(user_limit)
	return self:_modify({user_limit = user_limit or json.null})
end

--[[
@property bitrate: number
]]
function get.bitrate(self)
	return self._bitrate
end

--[[
@property userLimit: number
]]
function get.userLimit(self)
	return self._user_limit
end

return GuildVoiceChannel
