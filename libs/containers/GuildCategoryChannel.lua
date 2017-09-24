local GuildChannel = require('containers/abstract/GuildChannel')

local GuildCategoryChannel = require('class')('GuildCategoryChannel', GuildChannel)

function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

return GuildCategoryChannel
