local User = require('./User')
local Snowflake = require('../Snowflake')

local Channel, get = class('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
	-- abstract class, don't call update
end

get('type', '_type')
get('isPrivate', '_is_private')

function Channel:_update(data)
	Snowflake._update(self, data)
end

function Channel:delete()
	local success, data = self.client._api:deleteChannel(self._id)
	return success
end

return Channel
