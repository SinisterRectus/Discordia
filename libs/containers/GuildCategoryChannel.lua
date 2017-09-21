local GuildChannel = require('containers/abstract/GuildChannel')

local GuildCategoryChannel = require('class')('GuildCategoryChannel', GuildChannel)

--[[
@class GuildCategoryChannel x GuildChannel

Represents a channel category in a Discord guild, used to organize individual
text or voice channels in that guild.
]]
function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

return GuildCategoryChannel
