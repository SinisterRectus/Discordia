--[=[
@c Date
@t ui
@mt mem
@op seconds number
@op microseconds number
@d Represents a single moment in time and provides utilities for converting to
and from different date and time formats. Although microsecond precision is available,
most formats are implemented with only second precision.
]=]

local ffi = require('ffi')
local class = require('class')
local constants = require('constants')
local Time = require('utils/Time')

local abs, modf, fmod, floor = math.abs, math.modf, math.fmod, math.floor
local format = string.format
local date, time, difftime = os.date, os.time, os.difftime
local typeof = ffi.typeof
local isInstance = class.isInstance

local MS_PER_S = constants.MS_PER_S
local US_PER_MS = constants.US_PER_MS
local US_PER_S = US_PER_MS * MS_PER_S

local DISCORD_EPOCH = constants.DISCORD_EPOCH

local uint64_t = typeof('uint64_t')

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
	return 'Date: ' .. self:toString()
end

--[=[
@m toString
@op fmt string
@r string
@d Returns a string from this Date object via Lua's `os.date`.
If no format string is provided, the default is '%a %b %d %Y %T GMT%z (%Z)'.
]=]
function Date:toString(fmt)
	if not fmt or fmt == '*t' or fmt == '!*t' then
		fmt = '%a %b %d %Y %T GMT%z (%Z)'
	end
	return date(fmt, self._s)
end

function Date:__eq(other) check(self, other)
	return self._s == other._s and self._us == other._us
end

function Date:__lt(other) check(self, other)
	return self:toMicroseconds() < other:toMicroseconds()
end

function Date:__le(other) check(self, other)
	return self:toMicroseconds() <= other:toMicroseconds()
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

--[=[
@m parseISO
@t static
@p str string
@r number
@r number
@d Converts an ISO 8601 string into a Unix time in seconds. For compatibility
with Discord's timestamp format, microseconds are also provided as a second
return value.
]=]
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

--[=[
@m parseHeader
@t static
@p str string
@r number
@d Converts an RFC 2822 string (an HTTP Date header) into a Unix time in seconds.
]=]
function Date.parseHeader(str)
	local day, month, year, hour, min, sec = str:match(
		'%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT'
	)
	return Date.parseTableUTC {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec, isdst = false,
	}
end

--[=[
@m parseSnowflake
@t static
@p id string
@r number
@d Converts a Discord Snowflake ID into a Unix time in seconds. Additional
decimal points may be present, though only the first 3 (milliseconds) should be
considered accurate.
]=]
function Date.parseSnowflake(id)
	return (id / 2^22 + DISCORD_EPOCH) / MS_PER_S
end

--[=[
@m parseTable
@t static
@p tbl table
@r number
@d Interprets a Lua date table as a local time and converts it to a Unix time in
seconds. Equivalent to `os.time(tbl)`.
]=]
function Date.parseTable(tbl)
	return time(tbl)
end

--[=[
@m parseTableUTC
@t static
@p tbl table
@r number
@d Interprets a Lua date table as a UTC time and converts it to a Unix time in
seconds. Equivalent to `os.time(tbl)` with a correction for UTC.
]=]
function Date.parseTableUTC(tbl)
	return time(tbl) + offset()
end

--[=[
@m fromISO
@t static
@p str string
@r Date
@d Constructs a new Date object from an ISO 8601 string. Equivalent to
`Date(Date.parseISO(str))`.
]=]
function Date.fromISO(str)
	return Date(Date.parseISO(str))
end

--[=[
@m fromHeader
@t static
@p str string
@r Date
@d Constructs a new Date object from an RFC 2822 string. Equivalent to
`Date(Date.parseHeader(str))`.
]=]
function Date.fromHeader(str)
	return Date(Date.parseHeader(str))
end

--[=[
@m fromSnowflake
@t static
@p id string
@r Date
@d Constructs a new Date object from a Discord/Twitter Snowflake ID. Equivalent to
`Date(Date.parseSnowflake(id))`.
]=]
function Date.fromSnowflake(id)
	return Date(Date.parseSnowflake(id))
end

--[=[
@m fromTable
@t static
@p tbl table
@r Date
@d Constructs a new Date object from a Lua date table interpreted as a local time.
Equivalent to `Date(Date.parseTable(tbl))`.
]=]
function Date.fromTable(tbl)
	return Date(Date.parseTable(tbl))
end

--[=[
@m fromTableUTC
@t static
@p tbl table
@r Date
@d Constructs a new Date object from a Lua date table interpreted as a UTC time.
Equivalent to `Date(Date.parseTableUTC(tbl))`.
]=]
function Date.fromTableUTC(tbl)
	return Date(Date.parseTableUTC(tbl))
end

--[=[
@m fromSeconds
@t static
@p s number
@r Date
@d Constructs a new Date object from a Unix time in seconds.
]=]
function Date.fromSeconds(s)
	return Date(s)
end

--[=[
@m fromMilliseconds
@t static
@p ms number
@r Date
@d Constructs a new Date object from a Unix time in milliseconds.
]=]
function Date.fromMilliseconds(ms)
	return Date(ms / MS_PER_S)
end

--[=[
@m fromMicroseconds
@t static
@p us number
@r Date
@d Constructs a new Date object from a Unix time in microseconds.
]=]
function Date.fromMicroseconds(us)
	return Date(0, us)
end

--[=[
@m toISO
@op sep string
@op tz string
@r string
@d Returns an ISO 8601 string that represents the stored date and time.
If `sep` and `tz` are both provided, then they are used as a custom separator
and timezone; otherwise, `T` is used for the separator and `+00:00` is used for
the timezone, plus microseconds if available.
]=]
function Date:toISO(sep, tz)
	if sep and tz then
		local ret = date('!%F%%s%T%%s', self._s)
		return format(ret, sep, tz)
	else
		if self._us == 0 then
			return date('!%FT%T', self._s) .. '+00:00'
		else
			return date('!%FT%T', self._s) .. format('.%06i+00:00', self._us)
		end
	end
end

--[=[
@m toHeader
@r string
@d Returns an RFC 2822 string that represents the stored date and time.
]=]
function Date:toHeader()
	return date('!%a, %d %b %Y %T GMT', self._s)
end

--[=[
@m toSnowflake
@r string
@d Returns a synthetic Discord Snowflake ID based on the stored date and time.
Note that `Date.fromSnowflake(id):toSnowflake()` may not return the original Snowflake.
]=]
function Date:toSnowflake()
	local n = uint64_t(self:toMilliseconds() - DISCORD_EPOCH) * 2^22
	return tostring(n):match('%d*')
end

--[=[
@m toTable
@r table
@d Returns a Lua date table that represents the stored date and time as a local
time. Equivalent to `os.date('*t', s)` where `s` is the Unix time in seconds.
]=]
function Date:toTable()
	return date('*t', self._s)
end

--[=[
@m toTableUTC
@r table
@d Returns a Lua date table that represents the stored date and time as a UTC
time. Equivalent to `os.date('!*t', s)` where `s` is the Unix time in seconds.
]=]
function Date:toTableUTC()
	return date('!*t', self._s)
end

--[=[
@m toSeconds
@r number
@d Returns a Unix time in seconds that represents the stored date and time.
]=]
function Date:toSeconds()
	return self._s + self._us / US_PER_S
end

--[=[
@m toMilliseconds
@r number
@d Returns a Unix time in milliseconds that represents the stored date and time.
]=]
function Date:toMilliseconds()
	return self._s * MS_PER_S + self._us / US_PER_MS
end

--[=[
@m toMicroseconds
@r number
@d Returns a Unix time in microseconds that represents the stored date and time.
]=]
function Date:toMicroseconds()
	return self._s * US_PER_S + self._us
end

--[=[
@m toParts
@r number
@r number
@d Returns the seconds and microseconds that are stored in the date object.
]=]
function Date:toParts()
	return self._s, self._us
end

return Date
