local constants = require('constants')

local DISCORD_EPOCH = constants.DISCORD_EPOCH
local MS_PER_S = constants.MS_PER_S

local Container = require('utils/Container')

local date = os.date
local modf = math.modf
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

function get.createdAt(self) -- TODO: move to utils or Date or Time class?
	return (self._id / 2^22 + DISCORD_EPOCH) / MS_PER_S
end

function get.timestamp(self) -- TODO: move to utils or Date or Time class?
	local i, f = modf(self.createdAt)
	return date('!%FT%T', i) .. format('%.6f', f):sub(2) .. '+00:00'
end

return Snowflake
