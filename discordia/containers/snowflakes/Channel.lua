local User = require('./User')
local Snowflake = require('../Snowflake')

local format = string.format

local Channel, property = class('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
	-- abstract class, don't call update
end

property('type', '_type', nil, 'string', "The channel type (text or voice)")
property('isPrivate', '_is_private', nil, 'boolean', "Whether the channel is prviate")

function Channel:_update(data)
	Snowflake._update(self, data)
end

function Channel:delete()
	local client = self._parent._parent or self._parent
	local success, data = client._api:deleteChannel(self._id)
	return success
end

return Channel
