local Date = require('utils/Date')
local Container = require('containers/abstract/Container')

local Snowflake, get = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

function Snowflake:__hash()
	return self._id
end

function get.id(self)
	return self._id
end

function get.createdAt(self)
	return Date.parseSnowflake(self._id)
end

function get.timestamp(self)
	return Date.fromSnowflake(self._id):toISO()
end

return Snowflake
