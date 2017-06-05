local Channel = require('containers/abstract/Channel')

local GuildChannel = require('class')('GuildChannel', Channel)

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
end

-- TODO: permission overwrites

return GuildChannel
