local Date = require('utils/Date')
local Container = require('containers/abstract/Container')
local constants = require('constants')

local US_PER_S = constants.US_PER_MS * constants.MS_PER_S

local date = os.date
local modf, floor = math.modf, math.floor
local format = string.format

local Snowflake = require('class')('Snowflake', Container)
local get = Snowflake.__getters

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
	local t, f = modf(self.createdAt)
	local micro = floor(US_PER_S * f + 0.5)
	if micro == 0 then
		return date('!%FT%T', t) .. '+00:00'
	else
		return date('!%FT%T', t) .. format('.%6i', micro) .. '+00:00'
	end
end

return Snowflake
