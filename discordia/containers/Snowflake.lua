local Container = require('../utils/Container')

local format = string.format

local Snowflake, property = class('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
	-- abstract class, don't call update
end

property('id', '_id', nil, 'string', "Snowflake ID for the object")
property('createdAt', function(self)
	local ms = self._id / 2^22 + 1420070400000
	return ms / 1000 -- return seconds for Lua consistency
end, nil, 'number', "Unix time in seconds at which the object was created by Discord")

function Snowflake:__tostring()
	return format('%s: %s', self.__name, self._id)
end

function Snowflake:_update(data)
	Container._update(self, data)
end

function Snowflake:__eq(other)
	return self.__name == other.__name and self._id == other._id
end

return Snowflake
