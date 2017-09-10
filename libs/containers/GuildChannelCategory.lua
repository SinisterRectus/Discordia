local GuildChannel = require('containers/abstract/GuildChannel')

local GuildChannelCategory = require('class')('GuildChannelCategory', GuildChannel)

--[[
@class GuildChannelCategory x GuildChannel

Represents a channel category in a Discord guild, used to organize individual
text or voice channels in that guild.
]]
function GuildChannelCategory:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

return GuildChannelCategory
