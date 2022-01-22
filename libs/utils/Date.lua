local uv = require('uv')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')
local constants = require('../constants')

local Time = require('./Time')

local gettimeofday = uv.gettimeofday
local isInstance = class.isInstance
local checkInteger, checkType = typing.checkInteger, typing.checkType
local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local floor, fmod, modf = math.floor, math.fmod, math.modf
local format = string.format
local date, time, difftime = os.date, os.time, os.difftime

local MS_PER_S = constants.MS_PER_S
local US_PER_MS = constants.US_PER_MS
local US_PER_S = US_PER_MS * MS_PER_S
local DISCORD_EPOCH = constants.DISCORD_EPOCH

local function offset()
	return difftime(time(), time(date('!*t')))
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
	date = {
		{'year', '(%d%d%d%d)', 1970},
		{'month', '%d%d%d%d%-(%d%d)', 1},
		{'day', '%d%d%d%d%-%d%d%-(%d%d)', 1},
	},
	time = {
		{'hour', '(%d%d)', 0},
		{'min', '%d%d:(%d%d)', 0},
		{'sec', '%d%d:%d%d:(%d%d)', 0},
		{'usec', '%d%d:%d%d:%d%d.(%d%d%d%d%d%d)', 0},
	},
}

local function toTime(tbl, utc)
	local new = {}
	for _, v in ipairs(properties.date) do
		new[v[1]] = floor(tbl[v[1]] or v[3])
	end
	for _, v in ipairs(properties.time) do
		new[v[1]] = floor(tbl[v[1]] or v[3])
	end
	if utc then
		new.isdst = false
	end
	local sec = time(new)
	if not sec then
		return error('date could not be converted to time', 2)
	end
	if utc then
		sec = sec + offset()
	end
	return normalize(sec, new.usec, US_PER_S)
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

function Date:__init(s, us)
	if s or us then
		s = s and checkInteger(s, 10, 0) or 0
		us = us and checkInteger(us, 10, 0) or 0
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

local function parseString(patterns, tbl, str)
	local valid = false
	for _, v in ipairs(patterns) do
		local i, j, n = str:find(v[2])
		if not valid and i == 1 and j == #str then
			valid = true
		end
		tbl[v[1]] = n or v[3]
	end
	if not valid then
		return error('invalid ISO 8601 string')
	end
	return tbl
end

function Date.fromISO(str)

	str = checkType('string', str)
	local tbl = {isdst = false}

	local d, t = str:match('(.*)T(.*)')
	parseString(properties.date, tbl, d or str)

	if t then
		local s, z, o = t:match('(.*)([Z%+%-])(.*)')
		if s and z and o then
			parseString(properties.time, tbl, s)
			if z ~= 'Z' and o ~= '00:00' then
				if z == '+' then
					for k, v in pairs(parseString(properties.time, {}, o)) do
						tbl[k] = tbl[k] + v
					end
				elseif z == '-' then
					for k, v in pairs(parseString(properties.time, {}, o)) do
						tbl[k] = tbl[k] - v
					end
				end
			end
		else
			parseString(properties.time, tbl, t)
		end
	end

	return Date.fromTableUTC(tbl)

end

function Date.fromSnowflake(id)
	return Date.fromMilliseconds(floor(checkSnowflake(id) / 2^22) + DISCORD_EPOCH)
end

function Date.fromTable(tbl)
	return Date(toTime(checkType('table', tbl)))
end

function Date.fromTableUTC(tbl)
	return Date(toTime(checkType('table', tbl), true))
end

function Date.fromSeconds(s)
	return Date(checkInteger(s, 10, 0))
end

function Date.fromMilliseconds(ms)
	return Date(0, checkInteger(ms, 10, 0) * US_PER_MS)
end

function Date.fromMicroseconds(us)
	return Date(0, checkInteger(us, 10, 0))
end

function Date:toISO()
	local s, us = self:toParts()
	if us > 0 then
		return toDate('!%FT%T', s) .. format('.%06i', us)
	else
		return toDate('!%FT%T', s)
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

function Date:toMention(style)
	local t = floor(self:toSeconds())
	if style then
		return format('<t:%s:%s>', t, checkEnum(enums.timestampStyle, style))
	else
		return format('<t:%s>', t)
	end
end

return Date
