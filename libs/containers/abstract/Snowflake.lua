--[=[@abc Snowflake x Container desc]=]

local Date = require('utils/Date')
local Container = require('containers/abstract/Container')

local Snowflake, get = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

function Snowflake:__hash()
	return self._id
end

--[=[@p id type desc]=]
function get.id(self)
	return self._id
end

--[=[@p createdAt type desc]=]
function get.createdAt(self)
	return Date.parseSnowflake(self._id)
end

--[=[@p timestamp type desc]=]
function get.timestamp(self)
	return Date.fromSnowflake(self._id):toISO()
end

return Snowflake
