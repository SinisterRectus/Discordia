local class = require('../class')
local typing = require('../typing')
local constants = require('../constants')

local fmod, modf = math.fmod, math.modf
local insert, concat = table.insert, table.concat
local isInstance = class.isInstance
local checkNumber = typing.checkNumber

local US_PER_MS   =               constants.US_PER_MS
local US_PER_S    = US_PER_MS   * constants.MS_PER_S
local US_PER_MIN  = US_PER_S    * constants.S_PER_MIN
local US_PER_HOUR = US_PER_MIN  * constants.MIN_PER_HOUR
local US_PER_DAY  = US_PER_HOUR * constants.HOUR_PER_DAY
local US_PER_WEEK = US_PER_DAY  * constants.DAY_PER_WEEK

local units = {
	{'weeks', US_PER_WEEK},
	{'days', US_PER_DAY},
	{'hours', US_PER_HOUR},
	{'minutes', US_PER_MIN},
	{'seconds', US_PER_S},
	{'milliseconds', US_PER_MS},
	{'microseconds', 1},
}

local function decompose(a, b)
	return modf(a / b), fmod(a, b)
end

local Time, get = class('Time')

local function checkTime(obj)
	if isInstance(obj, Time) then
		return obj.value
	end
	return error('cannot perform operation', 2)
end

function Time:__init(value)
	self._value = value and checkNumber(value) or 0
end

function Time:__eq(other)
	return checkTime(self) == checkTime(other)
end

function Time:__lt(other)
	return checkTime(self) < checkTime(other)
end

function Time:__le(other)
	return checkTime(self) <= checkTime(other)
end

function Time:__add(other)
	return Time(checkTime(self) + checkTime(other))
end

function Time:__sub(other)
	return Time(checkTime(self) - checkTime(other))
end

function Time:__mod(other)
	return Time(checkTime(self) % checkTime(other))
end

function Time:__mul(other)
	if tonumber(other) then
		return Time(checkTime(self) * other)
	elseif tonumber(self) then
		return Time(self * checkTime(other))
	else
		return error('cannot perform operation')
	end
end

function Time:__div(other)
	if tonumber(other) then
		return Time(checkTime(self) / other)
	elseif tonumber(self) then
		return error('division not commutative')
	else
		return error('cannot perform operation')
	end
end

function Time:toString()
	local ret = {}
	local v = self._value
	for _, unit in ipairs(units) do
		local n
		n, v = decompose(v, unit[2])
		if n == 1 or n == -1 then
			insert(ret, n .. ' ' .. unit[1]:sub(1, -2))
		elseif n ~= 0 then
			insert(ret, n .. ' ' .. unit[1])
		end
	end
	return #ret > 0 and concat(ret, ', ') or '0 ' .. units[#units][1]
end

function Time.fromWeeks(t)
	return Time(checkNumber(t) * US_PER_WEEK)
end

function Time.fromDays(t)
	return Time(checkNumber(t) * US_PER_DAY)
end

function Time.fromHours(t)
	return Time(checkNumber(t) * US_PER_HOUR)
end

function Time.fromMinutes(t)
	return Time(checkNumber(t) * US_PER_MIN)
end
function Time.fromSeconds(t)
	return Time(checkNumber(t) * US_PER_S)
end

function Time.fromMilliseconds(t)
	return Time(checkNumber(t) * US_PER_MS)
end

function Time.fromMicroseconds(t)
	return Time(checkNumber(t))
end

function Time.fromTable(t)
	local n = 0
	for _, v in ipairs(units) do
		local m = t[v[1]]
		if m then
			n = n + checkNumber(m) * v[2]
		end
	end
	return Time(n)
end

function Time:toWeeks()
	return self._value / US_PER_WEEK
end

function Time:toDays()
	return self._value / US_PER_DAY
end

function Time:toHours()
	return self._value / US_PER_HOUR
end

function Time:toMinutes()
	return self._value / US_PER_MIN
end

function Time:toSeconds()
	return self._value / US_PER_S
end

function Time:toMilliseconds()
	return self._value / US_PER_MS
end

function Time:toMicroseconds()
	return self._value
end

function Time:toTable()
	local ret = {}
	local v = self._value
	for _, unit in ipairs(units) do
		ret[unit[1]], v = decompose(v, unit[2])
	end
	return ret
end

----

function get:value()
	return self._value
end

return Time
