local json = require('json')
local f = string.format

local function typeError(expected, received)
	return error(f('expected %s, received %s', expected, received), 2)
end

local function opt(obj, fn, extra)
	if obj == nil or obj == json.null then
		return obj
	elseif extra then
		return fn(extra, obj)
	else
		return fn(obj)
	end
end

local function checkType(expected, obj)
	local received = type(obj)
	if received ~= expected then
		return typeError(expected, received)
	end
	return obj
end

local function checkNumber(obj, base, mn, mx)
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

local function checkInteger(obj, base, mn, mx)
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

local function checkString(obj, mn, mx)
	local str = tostring(obj)
	if not str then
		return typeError('string', type(obj))
	end
	local n = #str
	if mn and n < mn then
		return typeError('minimum length ' .. mn, n)
	end
	if mx and n > mx then
		return typeError('maximum length ' .. mx, n)
	end
	return str
end

local function checkStringStrict(obj, mn, mx)
	if type(obj) ~= 'string' then
		return typeError('string', type(obj))
	end
	local n = #obj
	if mn and n < mn then
		return typeError('minimum length ' .. mn, n)
	end
	if mx and n > mx then
		return typeError('maximum length ' .. mx, n)
	end
	return obj
end

local function checkCallable(obj)
	if type(obj) == 'function' then
		return obj
	end
	local meta = getmetatable(obj)
	if meta and type(meta.__call) == 'function' then
		return obj
	end
	return typeError('callable', type(obj))
end

local function checkSnowflake(obj)
	local t = type(obj)
	if t == 'string' and tonumber(obj) then
		return obj
	elseif t == 'number' and obj < 2^32 then
		return f('%i', obj)
	elseif t == 'table' then
		return checkSnowflake(obj.id)
	end
	return error('Snowflake ID should be an integral string', 2)
end

return {
	checkType = checkType,
	checkNumber = checkNumber,
	checkInteger = checkInteger,
	checkSnowflake = checkSnowflake,
}