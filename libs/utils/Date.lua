local uv = require('uv')
local class = require('../class')
local helpers = require('../helpers')
local constants = require('../constants')

local Time = require('./Time')

local gettimeofday = uv.gettimeofday
local isInstance = class.isInstance
local checkNumber = helpers.checkNumber
local floor, fmod, modf = math.floor, math.fmod, math.modf
local format = string.format
local date, time, difftime = os.date, os.time, os.difftime

local MS_PER_S = constants.MS_PER_S
local US_PER_MS = constants.US_PER_MS
local US_PER_S = US_PER_MS * MS_PER_S
local DISCORD_EPOCH = 1420070400000

local function offset()
	return difftime(time(), time(date('!*t')))
end

local function checkPosInt(n)
	return checkNumber(n, 10, true, 0)
end

local function decompose(a, b, c)
	return modf(a / b), fmod(a, b) * c
end

local function normalize(x, y, z)
	local a, b = decompose(x, 1, z)
	local c, d = decompose(y, z, 1)
	return a + c, b + d
end

local properties = { -- name, pattern, default
	{'year', '(%d%d%d%d)', 1970},
	{'month', '%d%d%d%d%-(%d%d)', 1},
	{'day', '%d%d%d%d%-%d%d%-(%d%d)', 1},
	{'hour', '%d%d%d%d%-%d%d%-%d%d.(%d%d)', 0},
	{'min', '%d%d%d%d%-%d%d%-%d%d.%d%d:(%d%d)', 0},
	{'sec', '%d%d%d%d%-%d%d%-%d%d.%d%d:%d%d:(%d%d)', 0},
	{'usec', '%d%d%d%d%-%d%d%-%d%d.%d%d:%d%d:%d%d.(%d%d%d%d%d%d)', 0},
}

local function toTime(tbl, utc)
	if type(tbl) ~= 'table' then
		return error('invalid date table', 2)
	end
	for _, v in ipairs(properties) do
		tbl[v[1]] = floor(tbl[v[1]] or v[3])
	end
	if utc then
		tbl.isdst = false
		return normalize(time(tbl) + offset(), tbl.usec, US_PER_S)
	else
		return normalize(time(tbl), tbl.usec, US_PER_S)
	end
end

local function toDate(fmt, t)
	local d = date(fmt, t)
	if not d then
		return error('time could not be converted to date', 2)
	end
	return d
end

local Date = class('Date')

local function checkDate(obj)
	if isInstance(obj, Date) then
		return obj:toMicroseconds()
	end
	return error('cannot perform operation', 2)
end

local function checkSeparator(sep)
	sep = tostring(sep)
	if not sep or #sep ~= 1 then
		return error('invalid ISO 8601 separator', 2)
	end
	return sep
end

function Date:__init(s, us)
	if s or us then
		s = s and checkPosInt(s) or 0
		us = us and checkPosInt(us) or 0
	else
		s, us = gettimeofday()
	end
	self._s, self._us = s, us
end

function Date:__eq(other)
	return checkDate(self) == checkDate(other)
end

function Date:__lt(other)
	return checkDate(self) < checkDate(other)
end

function Date:__le(other)
	return checkDate(self) <= checkDate(other)
end

function Date:__add(other)
	if isInstance(other, Time) then
		local n = self:toMicroseconds() + other:toMicroseconds()
		if n >= 0 and n % 1 == 0 then
			return Date.fromMicroseconds(n)
		end
	end
	return error('cannot perform operation')
end

function Date:__sub(other)
	if isInstance(other, Date) then
		return Time.fromMicroseconds(self:toMicroseconds() - other:toMicroseconds())
	elseif isInstance(other, Time) then
		local n = self:toMicroseconds() - other:toMicroseconds()
		if n >= 0 and n % 1 == 0 then
			return Date.fromMicroseconds(n)
		end
	end
	return error('cannot perform operation')
end

function Date.__mod()
	return error('cannot perform operation')
end

function Date.__mul()
	return error('cannot perform operation')
end

function Date.__div()
	return error('cannot perform operation')
end

function Date.fromISO(str)
	str = tostring(str)
	local tbl = {isdst = false}
	local valid = false
	for _, v in ipairs(properties) do
		local i, j, n = str:find(v[2])
		if not valid and i == 1 and j == #str then
			valid = true
		end
		tbl[v[1]] = n or v[3]
	end
	if not valid then
		return error('invalid ISO 8601 string')
	end
	return Date.fromTableUTC(tbl)
end

function Date.fromSnowflake(id)
	return Date.fromMilliseconds(floor(id / 2^22) + DISCORD_EPOCH)
end

function Date.fromTable(tbl)
	return Date(toTime(tbl))
end

function Date.fromTableUTC(tbl)
	return Date(toTime(tbl, true))
end

function Date.fromSeconds(s)
	return Date(checkPosInt(s))
end

function Date.fromMilliseconds(ms)
	return Date(0, checkPosInt(ms) * US_PER_MS)
end

function Date.fromMicroseconds(us)
	return Date(0, checkPosInt(us))
end

function Date:toISO(sep)
	sep = sep and checkSeparator(sep) or 'T'
	local s, us = self:toParts()
	if us > 0 then
		local str = toDate('!%F%%s%T%%s', s)
		return format(str, sep, format('.%06i', us))
	else
		local str = toDate('!%F%%s%T', s)
		return format(str, sep)
	end
end

function Date:toSnowflake()
	return format('%i', (self:toMilliseconds() - DISCORD_EPOCH) * 2^22)
end

function Date:toTable()
	local sec, usec = self:toParts()
	local tbl = toDate('*t', sec)
	tbl.usec = usec
	return tbl
end

function Date:toTableUTC()
	local sec, usec = self:toParts()
	local tbl = toDate('!*t', sec)
	tbl.usec = usec
	return tbl
end

function Date:toString(fmt)
	return toDate(fmt, self:toSeconds())
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
	return normalize(self._s, self._us, US_PER_S)
end

return Date
