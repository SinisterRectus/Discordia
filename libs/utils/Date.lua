local class = require('class')
local constants = require('constants')
local Time = require('utils/Time')

local abs = math.abs
local format = string.format
local date, time, difftime = os.date, os.time, os.difftime

local MS_PER_S = constants.MS_PER_S
local US_PER_MS = constants.US_PER_MS
local US_PER_S = US_PER_MS * MS_PER_S
local isInstance = class.isInstance

local months = {
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}

local function offset() -- difference between *t and !*t
	return difftime(time(), time(date('!*t')))
end

local Date = class('Date')

local function check(self, other)
	if not isInstance(self, Date) or not isInstance(other, Date) then
		return error('Cannot perform operation with non-Date object', 2)
	end
end

function Date:__init(value)
	self._value = tonumber(value) or time()
end

function Date:__tostring()
	return date('%a %b %d %Y %T GMT%z (%Z)', self._value)
end

function Date:__eq(other) check(self, other)
	return self._value == other._value
end

function Date:__lt(other) check(self, other)
	return self._value < other._value
end

function Date:__le(other) check(self, other)
	return self._value <= other._value
end

function Date:__add(other)
	if not isInstance(self, Date) then
		self, other = other, self
	end
	if not isInstance(other, Time) then
		return error('Cannot perform operation with non-Time object')
	end
	return Date(self:toSeconds() + other:toSeconds())
end

function Date:__sub(other)
	if isInstance(self, Date) then
		if isInstance(other, Date) then
			return Time(abs(self:toMilliseconds() - other:toMilliseconds()))
		elseif isInstance(other, Time) then
			return Date(self:toSeconds() - other:toSeconds())
		else
			return error('Cannot perform operation with non-Date/Time object')
		end
	else
		return error('Cannot perform operation with non-Date object')
	end
end

function Date.parseISO(str) -- ISO8601
	local year, month, day, hour, min, sec, other = str:match(
		'(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)(.*)'
	)
	other = other:match('%.%d+')
	return Date.parseTableUTC {
		day = day, month = month, year = year,
		hour = hour, min = min, sec = sec, isdst = false,
	}, other and other * US_PER_S
end

function Date.parseHeader(str) -- RFC2822
	local day, month, year, hour, min, sec = str:match(
		'%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT'
	)
	return Date.parseTableUTC {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec, isdst = false,
	}
end

function Date.parseTable(tbl)
	return time(tbl)
end

function Date.parseTableUTC(tbl)
	return time(tbl) + offset()
end

function Date.fromISO(str)
	return Date(Date.parseISO(str))
end

function Date.fromHeader(str)
	return Date(Date.parseHeader(str))
end

function Date.fromTable(tbl)
	return Date(Date.parseTable(tbl))
end

function Date.fromTableUTC(tbl)
	return Date(Date.parseTableUTC(tbl))
end

function Date.fromSeconds(t)
	return Date(t)
end

function Date.fromMilliseconds(t)
	return Date(t / MS_PER_S)
end

function Date:toISO(sep, tz)
	local ret = date('!%F%%s%T%%s', self._seconds)
	return format(ret, sep or 'T', tz or 'Z')
end

function Date:toHeader()
	return date('!%a, %d %b %Y %T GMT', self._value)
end

function Date:toTable()
	return date('*t', self._value)
end

function Date:toTableUTC()
	return date('!*t', self._value)
end

function Date:toSeconds()
	return self._value
end

function Date:toMilliseconds()
	return self._value * MS_PER_S
end

return Date
