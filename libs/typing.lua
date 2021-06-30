local fs = require('fs')
local ssl = require('openssl')

local base64 = ssl.base64
local format = string.format
local readFileSync = fs.readFileSync

local function typeError(expected, received)
	return error(format('expected %s, received %s', expected, received), 2)
end

local typing = {}

function typing.checkType(expected, obj)
	local received = type(obj)
	if received ~= expected then
		return typeError(expected, received)
	end
	return obj
end

function typing.checkNumber(obj, base, mn, mx)
	local success, n = pcall(tonumber, obj, base)
	if not success or not n then
		return typeError('number', type(obj))
	end
	if mn and n < mn then
		return typeError('minimum ' .. mn, n)
	end
	if mx and n > mx then
		return typeError('maximum ' .. mx, n)
	end
	return n
end

function typing.checkInteger(obj, base, mn, mx)
	local success, n = pcall(tonumber, obj, base)
	if not success or not n then
		return typeError('integer', type(obj))
	end
	if n % 1 ~= 0 then
		return typeError('integer', n)
	end
	if mn and n < mn then
		return typeError('minimum ' .. mn, n)
	end
	if mx and n > mx then
		return typeError('maximum ' .. mx, n)
	end
	return n
end

function typing.checkCallable(obj)
	if type(obj) == 'function' then
		return obj
	else
		local meta = getmetatable(obj)
		if meta and type(meta.__call) == 'function' then
			return obj
		end
	end
	return typeError('callable', type(obj))
end

function typing.checkEnum(enum, obj)
	local _, v = enum(obj)
	return v
end

function typing.checkSnowflake(obj)
	local t = type(obj)
	if t == 'string' and tonumber(obj) then
		return obj
	elseif t == 'number' and obj < 2^32 then
		return format('%i', obj)
	elseif t == 'table' then
		return typing.checkSnowflake(obj.id)
	elseif t == 'cdata' and tonumber(obj) then
		return tostring(obj):match('%d*')
	end
	return error('Snowflake ID should be an integral string', 2)
end

function typing.checkSnowflakeArray(obj)
	local t = type(obj)
	if t ~= 'table' then
		return typeError('table', t)
	end
	local arr = {}
	for _, v in pairs(obj) do
		arr[#arr + 1] = typing.checkSnowflake(v)
	end
	return arr
end

local function imageType(data)
	if data:sub(1, 8) == '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A' then
		return 'image/png'
	elseif data:sub(1, 3) == '\xFF\xD8\xFF' then
		return 'image/jpeg'
	elseif data:sub(1, 6) == '\x47\x49\x46\x38\x37\x61' then
		return 'image/gif'
	elseif data:sub(1, 6) == '\x47\x49\x46\x38\x39\x61' then
		return 'image/gif'
	elseif data:sub(1, 4) == 'RIFF' and data:sub(9, 12) == 'WEBP' then
		return 'image/webp'
	end
end

function typing.checkImageData(str)
	local t = type(str)
	if t ~= 'string' then
		return typeError('image', t)
	end
	local data = readFileSync(str) or str
	t = imageType(data)
	if not t then
		return typeError('image', type(data))
	end
	return 'data:' .. t .. ';base64,' .. base64(data)
end

local sizes = {
	[16] = true, [32] = true,
	[64] = true, [128] = true,
	[256] = true, [1024] = true,
	[2048] = true, [4096] = true,
}

function typing.checkImageSize(size)
	if not sizes[size] then
		return error('invalid image size; must be a power of 2 between 16 and 4096', 2)
	end
	return size
end

local extensions = {
	['jpg'] = true,
	['jpeg'] = true,
	['png'] = true,
	['webp'] = true,
	['gif'] = true,
}

function typing.checkImageExtension(ext)
	if not extensions[ext] then
		return error('invalid image extension; must be one of: jpg, jpeg, png, webp, gif', 2)
	end
	return ext
end

return typing
