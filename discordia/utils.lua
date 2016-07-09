local date = os.date
local fmod = math.fmod
local insert = table.insert
local gmatch, upper = string.gmatch, string.upper
local ipairs, pairs, type = ipairs, pairs, type

local function camelify(obj)
	if type(obj) == 'string' then
		local str, count = obj:lower():gsub('_%l', upper):gsub('_', '')
		return str
	elseif type(obj) == 'table' then
		local tbl = {}
		for k, v in pairs(obj) do
			tbl[camelify(k)] = type(v) == 'table' and camelify(v) or v
		end
		return tbl
	end
	return obj
end

local function numToBin(num, bits)
	bits = bits or 1
	local bin = {}
	while num > 0 or #bin < bits do
		local r = fmod(num, 2)
		insert(bin, r)
		num = (num - r) / 2
	end
	return bin
end

local function binToNum(bin)
	local n = 0
	for i, bit in ipairs(bin) do
		if bit == 1 then
			n = n + 2^(i - 1)
		end
	end
	return n
end

local function binaryAdd(a, b)
	local n = #a
	local c, r = {}, {}
	for i = 1, n do
		c[i], r[i] = 0, 0
	end
	local remainder
	for i = 1, n do
		if a[i] == 1 and b[i] == 1 then
			remainder = true
			r[i + 1] = (r[i + 1] or 0) + 1
		else
			c[i] = c[i] + a[i] + b[i]
		end
	end
	if remainder then c = binaryAdd(c, r) end
	return c
end

local function rightShift(bin, bits)
	local new = {}
	for i = bits, #bin do
		new[i - bits] = bin[i]
	end
	return new
end

local function snowflakeToBinary(id)
	local a, b = 0, 0
	local i, n = 1, #id
	for digit in gmatch(id, '%d') do
		if i < n / 2 then
			a = a + digit * 10^(n - i)
		else
			b = b + digit * 10^(n - i)
		end
		i = i + 1
	end
	return binaryAdd(numToBin(a, 64), numToBin(b, 64))
end

local function snowflakeToTime(id) -- returns seconds
	local bin = snowflakeToBinary(id)
	local shifted = rightShift(bin, 22)
	return (binToNum(shifted) + 1420070400000) / 1000
end

local function snowflakeToDate(id, format)
	return date(format or '!%Y-%m-%d %H:%M:%S', snowflakeToTime(id))
end

local function dateToTime(dateString)
	local pattern = '(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)'
	if dateString:find('%.') then pattern = pattern .. '%.(%d+)' end
	local year, month, day, hour, min, sec, msec = string.match(dateString, pattern)
	local lt, ut = os.date('*t'), os.date('!*t')
	local dt = os.time(lt) - os.time(ut)
	if lt.isdst then dt = dt + 3600 end
	local time = os.time({
		year = year, month = month,
		day = day, hour = hour,
		min = min, sec = sec,
	}) + dt
	if msec then time = time + msec:gsub("0*$", "") / 1000 end
	return time
end

local function isInstanceOf(obj, class)
	if obj.__index == class then return true end
	for _, base in ipairs(obj.__index.__bases) do
		if base == class then
			return true
		else
			return isInstanceOf(base, class)
		end
	end
end

return {
	camelify = camelify,
	dateToTime = dateToTime,
	snowflakeToTime = snowflakeToTime,
	snowflakeToDate = snowflakeToDate,
	isInstanceOf = isInstanceOf,
}
