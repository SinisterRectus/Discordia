local class = require('class')
local constants = require('constants')
local Time = require('utils/Time')

local abs, modf, fmod, floor = math.abs, math.modf, math.fmod, math.floor
local format = string.format
local date, time, difftime = os.date, os.time, os.difftime
local isInstance = class.isInstance

local MS_PER_S = constants.MS_PER_S
local US_PER_MS = constants.US_PER_MS
local US_PER_S = US_PER_MS * MS_PER_S

local DISCORD_EPOCH = constants.DISCORD_EPOCH

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

function Date:__init(seconds, micro)

	local f
	seconds = tonumber(seconds)
	if seconds then
		seconds, f = modf(seconds)
	else
		seconds = time()
	end

	micro = tonumber(micro)
	if micro then
		seconds = seconds + modf(micro / US_PER_S)
		micro = fmod(micro, US_PER_S)
	else
		micro = 0
	end

	if f and f > 0 then
		micro = micro + US_PER_S * f
	end

	self._s = seconds
	self._us = floor(micro + 0.5)

end

function Date:__tostring()
	return date('%a %b %d %Y %T GMT%z (%Z)', self._s)
end

function Date:__eq(other) check(self, other)
	return self._s == other._s and self._us == other._us
end

function Date:__lt(other) check(self, other)
	return self._s < other._s and self._us < other._us
end

function Date:__le(other) check(self, other)
	return self._s <= other._s and self._us < other._us
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

function Date.parseISO(str)
	local year, month, day, hour, min, sec, other = str:match(
		'(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)(.*)'
	)
	other = other:match('%.%d+')
	return Date.parseTableUTC {
		day = day, month = month, year = year,
		hour = hour, min = min, sec = sec, isdst = false,
	}, other and other * US_PER_S or 0
end

function Date.parseHeader(str)
	local day, month, year, hour, min, sec = str:match(
		'%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT'
	)
	return Date.parseTableUTC {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec, isdst = false,
	}
end

function Date.parseSnowflake(id)
	return (id / 2^22 + DISCORD_EPOCH) / MS_PER_S
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

function Date.fromSnowflake(id)
	return Date(Date.parseSnowflake(id))
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

function Date.fromMicroseconds(t)
	return Date(0, t)
end

function Date:toISO(sep, tz)
	if sep and tz then
		local ret = date('!%F%%s%T%%s', self._s)
		return format(ret, sep, tz)
	else
		if self._us == 0 then
			return date('!%FT%T', self._s) .. '+00:00'
		else
			return date('!%FT%T', self._s) .. format('.%6i', self._us) .. '+00:00'
		end
	end
end

function Date:toHeader()
	return date('!%a, %d %b %Y %T GMT', self._s)
end

function Date:toSnowflake()
	return format('%i', (self:toMilliseconds() - DISCORD_EPOCH) * 2^22)
end

function Date:toTable()
	return date('*t', self._s)
end

function Date:toTableUTC()
	return date('!*t', self._s)
end

function Date:toSeconds()
	return self._s + self._us / US_PER_S
end

function Date:toMilliseconds()
	return self._s * MS_PER_S + self._us / US_PER_MS
end

function Date:toMicroseconds()
	return self._s * US_PER_S + self._us
end

function Date:toParts()
	return self._s, self._us
end

return Date
