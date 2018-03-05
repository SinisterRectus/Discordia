local class = require('class')
local constants = require('constants')

local MS_PER_S    =               constants.MS_PER_S
local MS_PER_MIN  = MS_PER_S    * constants.S_PER_MIN
local MS_PER_HOUR = MS_PER_MIN  * constants.MIN_PER_HOUR
local MS_PER_DAY  = MS_PER_HOUR * constants.HOUR_PER_DAY
local MS_PER_WEEK = MS_PER_DAY  * constants.DAY_PER_WEEK

local DAY_PER_WEEK = constants.DAY_PER_WEEK
local HOUR_PER_DAY = constants.HOUR_PER_DAY
local MIN_PER_HOUR = constants.MIN_PER_HOUR
local S_PER_MIN    = constants.S_PER_MIN

local insert, concat = table.insert, table.concat
local modf, fmod = math.modf, math.fmod
local isInstance = class.isInstance

local from = {
	weeks = MS_PER_WEEK,
	days = MS_PER_DAY,
	hours = MS_PER_HOUR,
	minutes = MS_PER_MIN,
	seconds = MS_PER_S,
	milliseconds = 1,
}

local Time = class('Time')

local function check(self, other)
	if not isInstance(self, Time) or not isInstance(other, Time) then
		return error('Cannot perform operation with non-Time object', 2)
	end
end

function Time:__init(value)
	self._value = tonumber(value) or 0
end

local function addString(unit, tbl, ret)
	if tbl[unit] == 1 then
		insert(ret, tbl[unit] .. ' ' .. unit:sub(1, #unit - 1))
	elseif tbl[unit] > 0 then
		insert(ret, tbl[unit] .. ' ' .. unit)
	end
end

function Time:__tostring()
	return 'Time: ' .. self:toString()
end

function Time:toString()
	local tbl = self:toTable()
	local ret = {}
	addString('weeks', tbl, ret)
	addString('days', tbl, ret)
	addString('hours', tbl, ret)
	addString('minutes', tbl, ret)
	addString('seconds', tbl, ret)
	addString('milliseconds', tbl, ret)
	return concat(ret, ', ')
end

function Time:__eq(other) check(self, other)
	return self._value == other._value
end

function Time:__lt(other) check(self, other)
	return self._value < other._value
end

function Time:__le(other) check(self, other)
	return self._value <= other._value
end

function Time:__add(other) check(self, other)
	return Time(self._value + other._value)
end

function Time:__sub(other) check(self, other)
	return Time(self._value - other._value)
end

function Time:__mul(other)
	if not isInstance(self, Time) then
		self, other = other, self
	end
	other = tonumber(other)
	if other then
		return Time(self._value * other)
	else
		return error('Cannot perform operation with non-numeric object')
	end
end

function Time:__div(other)
	if not isInstance(self, Time) then
		return error('Division with Time is not commutative')
	end
	other = tonumber(other)
	if other then
		return Time(self._value / other)
	else
		return error('Cannot perform operation with non-numeric object')
	end
end

function Time.fromWeeks(t)
	return Time(t * MS_PER_WEEK)
end

function Time.fromDays(t)
	return Time(t * MS_PER_DAY)
end

function Time.fromHours(t)
	return Time(t * MS_PER_HOUR)
end

function Time.fromMinutes(t)
	return Time(t * MS_PER_MIN)
end

function Time.fromSeconds(t)
	return Time(t * MS_PER_S)
end

function Time.fromMilliseconds(t)
	return Time(t)
end

function Time.fromTable(t)
	local n = 0
	for k, v in pairs(from) do
		local m = tonumber(t[k])
		if m then
			n = n + m * v
		end
	end
	return Time(n)
end

function Time:toWeeks()
	return self:toMilliseconds() / MS_PER_WEEK
end

function Time:toDays()
	return self:toMilliseconds() / MS_PER_DAY
end

function Time:toHours()
	return self:toMilliseconds() / MS_PER_HOUR
end

function Time:toMinutes()
	return self:toMilliseconds() / MS_PER_MIN
end

function Time:toSeconds()
	return self:toMilliseconds() / MS_PER_S
end

function Time:toMilliseconds()
	return self._value
end

function Time:toTable()
	local v = self._value
	return {
		weeks = modf(v / MS_PER_WEEK),
		days = modf(fmod(v / MS_PER_DAY, DAY_PER_WEEK)),
		hours = modf(fmod(v / MS_PER_HOUR, HOUR_PER_DAY)),
		minutes = modf(fmod(v / MS_PER_MIN, MIN_PER_HOUR)),
		seconds = modf(fmod(v / MS_PER_S, S_PER_MIN)),
		milliseconds = modf(fmod(v, MS_PER_S)),
	}
end

return Time
