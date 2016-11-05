local Snowflake = require('../Snowflake')

local Channel, property, method = class('Channel', Snowflake)
Channel.__description = "Abstract base class for more specific channel types."

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
	-- abstract class, don't call update
end

function Channel:_update(data)
	Snowflake._update(self, data)
end

local function delete(self)
	local client = self._parent._parent or self._parent
	return (client._api:deleteChannel(self._id))
end

property('type', '_type', nil, 'string', "The channel type (text or voice)")
property('isPrivate', '_is_private', nil, 'boolean', "Whether the channel is private")

method('delete', delete, nil, "Deletes the channel. This cannot be undone for guild channels!")

return Channel
