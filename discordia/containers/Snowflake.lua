local Container = require('../utils/Container')

local date = os.date
local modf = math.modf
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
	return (self._id / 2^22 + 1420070400000) / 1000
end

local function getTimestamp(self)
	local i, f = modf(self.createdAt)
	local datetime = date('!%Y-%m-%dT%H:%M:%S', i)
	return format('%s%s+00:00', datetime, format('%.6f', f):sub(2))
end

property('id', '_id', nil, 'string', "Snowflake ID for the object")
property('createdAt', getCreatedAt, nil, 'number', "Unix time in seconds at which the object was created by Discord")
property('timestamp', getTimestamp, nil, 'string', "ISO 8601 date and time at which the object was created by Discord")

return Snowflake
