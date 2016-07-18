local Container = require('../utils/Container')

local Snowflake, accessors = class('Snowflake', Container)

accessors.createdAt = function(self)
	local ms = self.id / 2^22 + 1420070400000
	return ms / 1000 -- return seconds for Lua consistency
end

function Snowflake:__init(data, parent)
	Container.__init(self, parent)
	self.id = data.id
end

function Snowflake:__tostring()
	return string.format('%s: %s', self.__name, self.name or self.id)
end

function Snowflake:__eq(other)
	return self.__class == other.__class and self.id == other.id
end

return Snowflake
