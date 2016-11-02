local User = require('./User')
local Snowflake = require('../Snowflake')

local Channel, get = class('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
	-- abstract class, don't call update
end

get('type', '_type', 'string')
get('isPrivate', '_is_private', 'boolean')

function Channel:_update(data)
	Snowflake._update(self, data)
end

function Channel:delete()
	local client = self._parent._parent or self._parent
	local success, data = client._api:deleteChannel(self._id)
	return success
end

return Channel
