local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')

local GuildVoiceChannel, get = require('class')('GuildVoiceChannel', GuildChannel)

--[[
@class GuildVoiceChannel x GuildChannel

Represents a voice channel in a Discord guild, where guild members can connect
and communicate via voice chat.
]]
function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

--[[
@method setBitrate
@tags http
@param bitrate: number
@ret boolean

Sets the channel's audio bitrate in bits per second (bps). This must be between
8000 and 96000 (or 128000 for partnered servers). If `nil` is passed, the
default is set, which is 64000.
]]
function GuildVoiceChannel:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate or json.null})
end

--[[
@method setUserLimit
@tags http
@param userLimit: number
@ret boolean

Sets the channel's user limit. This must be between 0 and 99 (where 0 is
unlimited). If `nil` is passed, the default is set, which is 0.
]]
function GuildVoiceChannel:setUserLimit(user_limit)
	return self:_modify({user_limit = user_limit or json.null})
end

--[[
@property bitrate: number

The channel's bitrate in bits per second (bps). This should be between 8000 and
96000 (or 128000 for partnered servers).
]]
function get.bitrate(self)
	return self._bitrate
end

--[[
@property userLimit: number

The channel's user limit. This should between 0 and 99 (where 0 is unlimited).
]]
function get.userLimit(self)
	return self._user_limit
end

return GuildVoiceChannel
