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
		return typeError('number', type(obj))
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
	local n = enum[obj] or enum(obj) and obj
	if not n then
		return typeError(tostring(enum), type(obj))
	end
	return n
end

local imageTypes = {
	['\xFF\xD8\xFF'] = 'image/jpeg',
	['\x47\x49\x46\x38\x37\x61'] = 'image/gif',
	['\x47\x49\x46\x38\x39\x61'] = 'image/gif',
	['\x89\x50\x4E\x47\x0D\x0A\x1A\x0A'] = 'image/png',
}

local function imageType(data)
	for k, v in pairs(imageTypes) do
		if data:sub(1, #k) == k then
			return v
		end
	end
end

function typing.checkImage(str)
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

return typing
