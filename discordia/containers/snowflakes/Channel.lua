local User = require('./User')
local Snowflake = require('../Snowflake')

local Channel = class('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.isPrivate = not not data.is_private
	self.type = data.type
end

function Channel:delete()
	local success, data = self.client.api:deleteChannel(self.id)
	return success
end

return Channel
