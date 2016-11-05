local Container = require('../utils/Container')

local format = string.format

local Snowflake, property = class('Snowflake', Container)
Snowflake.__description = "Abstract base class for Discord objects that have unique Snowflake IDs."

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
	-- abstract class, don't call update
end

function Snowflake:__tostring()
	return format('%s: %s', self.__name, self._id)
end

function Snowflake:__eq(other)
	return self.__name == other.__name and self._id == other._id
end

local function getCreatedAt(self)
	local ms = self._id / 2^22 + 1420070400000
	return ms / 1000 -- return seconds for Lua consistency
end

property('id', '_id', nil, 'string', "Snowflake ID for the object")
property('createdAt', getCreatedAt, nil, 'number', "Unix time in seconds at which the object was created by Discord")

return Snowflake
