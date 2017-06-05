local Container = require('utils/Container')

local format = string.format

local Snowflake, get = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

function Snowflake:__tostring()
	return format('%s: %s', self.__name, self._id)
end

function Snowflake:__eq(other)
	return self.__class == other.__class and self._id == other._id
end

function get.id(self)
	return self._id
end

return Snowflake
