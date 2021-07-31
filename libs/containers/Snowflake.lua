local Container = require('./Container')
local Date = require('../utils/Date')

local class = require('../class')

local Snowflake, get = class('Snowflake', Container)

function Snowflake:__init(data, client)
	Container.__init(self, data, client)
end

function Snowflake:__eq(other)
	return self.id == other.id
end

function Snowflake:toString()
	return self.id
end

function Snowflake:getDate()
	return Date.fromSnowflake(self.id)
end

function get:id()
	return self._id
end

return Snowflake
