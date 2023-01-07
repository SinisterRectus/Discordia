--[=[
@c Time
@t ui
@mt mem
@op value number
@d Represents a length of time and provides utilities for converting to and from
different formats. Supported units are: weeks, days, hours, minutes, seconds,
and milliseconds.
]=]

local class = require('class')
local constants = require('constants')

local MS_PER_S    =               constants.MS_PER_S
local MS_PER_MIN  = MS_PER_S    * constants.S_PER_MIN
local MS_PER_HOUR = MS_PER_MIN  * constants.MIN_PER_HOUR
local MS_PER_DAY  = MS_PER_HOUR * constants.HOUR_PER_DAY
local MS_PER_WEEK = MS_PER_DAY  * constants.DAY_PER_WEEK

local insert, concat = table.insert, table.concat
local modf, fmod = math.modf, math.fmod
local isInstance = class.isInstance

local function decompose(value, mult)
	return modf(value / mult), fmod(value, mult)
end

local units = {
	{'weeks', MS_PER_WEEK},
	{'days', MS_PER_DAY},
	{'hours', MS_PER_HOUR},
	{'minutes', MS_PER_MIN},
	{'seconds', MS_PER_S},
	{'milliseconds', 1},
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

function Time:__tostring()
	return 'Time: ' .. self:toString()
end

--[=[
@m toString
@r string
@d Returns a human-readable string built from the set of normalized time values
that the object represents.
]=]
function Time:toString()
	local ret = {}
	local ms = self:toMilliseconds()
	for _, unit in ipairs(units) do
		local n
		n, ms = decompose(ms, unit[2])
		if n == 1 then
			insert(ret, n .. ' ' .. unit[1]:sub(1, -2))
		elseif n > 0 then
			insert(ret, n .. ' ' .. unit[1])
		end
	end
	return #ret > 0 and concat(ret, ', ') or '0 milliseconds'
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

--[=[
@m fromWeeks
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as weeks, where a week
is equal to 7 days.
]=]
function Time.fromWeeks(t)
	return Time(t * MS_PER_WEEK)
end

--[=[
@m fromDays
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as days, where a day is
equal to 24 hours.
]=]
function Time.fromDays(t)
	return Time(t * MS_PER_DAY)
end

--[=[
@m fromHours
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as hours, where an hour is
equal to 60 minutes.
]=]
function Time.fromHours(t)
	return Time(t * MS_PER_HOUR)
end

--[=[
@m fromMinutes
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as minutes, where a minute
is equal to 60 seconds.
]=]
function Time.fromMinutes(t)
	return Time(t * MS_PER_MIN)
end

--[=[
@m fromSeconds
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as seconds, where a second
is equal to 1000 milliseconds.
]=]
function Time.fromSeconds(t)
	return Time(t * MS_PER_S)
end

--[=[
@m fromMilliseconds
@t static
@p t number
@r Time
@d Constructs a new Time object from a value interpreted as milliseconds, the base
unit represented.
]=]
function Time.fromMilliseconds(t)
	return Time(t)
end

--[=[
@m fromTable
@t static
@p t table
@r Time
@d Constructs a new Time object from a table of time values where the keys are
defined in the constructors above (eg: `weeks`, `days`, `hours`).
]=]
function Time.fromTable(t)
	local n = 0
	for _, v in ipairs(units) do
		local m = tonumber(t[v[1]])
		if m then
			n = n + m * v[2]
		end
	end
	return Time(n)
end

--[=[
@m toWeeks
@r number
@d Returns the total number of weeks that the time object represents.
]=]
function Time:toWeeks()
	return self:toMilliseconds() / MS_PER_WEEK
end

--[=[
@m toDays
@r number
@d Returns the total number of days that the time object represents.
]=]
function Time:toDays()
	return self:toMilliseconds() / MS_PER_DAY
end

--[=[
@m toHours
@r number
@d Returns the total number of hours that the time object represents.
]=]
function Time:toHours()
	return self:toMilliseconds() / MS_PER_HOUR
end

--[=[
@m toMinutes
@r number
@d Returns the total number of minutes that the time object represents.
]=]
function Time:toMinutes()
	return self:toMilliseconds() / MS_PER_MIN
end

--[=[
@m toSeconds
@r number
@d Returns the total number of seconds that the time object represents.
]=]
function Time:toSeconds()
	return self:toMilliseconds() / MS_PER_S
end

--[=[
@m toMilliseconds
@r number
@d Returns the total number of milliseconds that the time object represents.
]=]
function Time:toMilliseconds()
	return self._value
end

--[=[
@m toTable
@r number
@d Returns a table of normalized time values that represent the time object in
a more accessible form.
]=]
function Time:toTable()
	local ret = {}
	local ms = self:toMilliseconds()
	for _, unit in ipairs(units) do
		ret[unit[1]], ms = decompose(ms, unit[2])
	end
	return ret
end

return Time
