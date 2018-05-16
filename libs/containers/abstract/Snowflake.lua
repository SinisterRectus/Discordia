--[=[@abc Snowflake x Container ...]=]

local Date = require('utils/Date')
local Container = require('containers/abstract/Container')

local Snowflake, get = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

function Snowflake:__hash()
	return self._id
end

--[=[@p id string ...]=]
function get.id(self)
	return self._id
end

--[=[@p createdAt number ...]=]
function get.createdAt(self)
	return Date.parseSnowflake(self._id)
end

--[=[@p timestamp string ...]=]
function get.timestamp(self)
	return Date.fromSnowflake(self._id):toISO()
end

return Snowflake
