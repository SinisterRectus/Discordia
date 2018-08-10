--[=[
@c Snowflake x Container
@d Abstract base class that defines the base methods and/or properties for all
Discord objects that have a Snowflake ID.
]=]

local Date = require('utils/Date')
local Container = require('containers/abstract/Container')

local Snowflake, get = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

--[=[
@m __hash
@r string
@d Returns `Snowflake.id`
]=]
function Snowflake:__hash()
	return self._id
end

--[=[@p id string The Snowflake ID that can be used to identify the object. This is guaranteed to
be unique except in cases where an object shares the ID of its parent.]=]
function get.id(self)
	return self._id
end

--[=[@p createdAt number The Unix time in seconds at which this object was created by Discord. Additional
decimal points may be present, though only the first 3 (milliseconds) should be
considered accurate.]=]
function get.createdAt(self)
	return Date.parseSnowflake(self._id)
end

--[=[@p timestamp string The date and time at which this object was created by Discord, represented as
an ISO 8601 string plus microseconds when available.

Equivalent to `Date.fromSnowflake(Snowflake.id):toISO()`.
]=]
function get.timestamp(self)
	return Date.fromSnowflake(self._id):toISO()
end

return Snowflake
