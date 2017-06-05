local GuildChannel = require('containers/abstract/GuildChannel')
local TextChannel = require('containers/abstract/TextChannel')

local GuildTextChannel = require('class')('GuildTextChannel', GuildChannel, TextChannel)

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
end

return GuildTextChannel
