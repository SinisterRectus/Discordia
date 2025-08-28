local json = require('json')

local function typeError(expected, received)
	return error(string.format('expected %s, received %s', expected, received))
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
		typeError(expected, received)
	end
	return obj
end

local function checkValue(obj)
	if obj == nil then
		typeError('value', 'nil')
	end
	return obj
end

local function checkNumber(obj, base, mn, mx)
	local success, n = pcall(tonumber, obj, base)
	if not success or not n then
		typeError('number', type(obj))
	elseif mn and n < mn then
		typeError('minimum ' .. mn, n)
	elseif mx and n > mx then
		typeError('maximum ' .. mx, n)
	end
	return n
end

local function checkInteger(obj, base, mn, mx)
	local success, n = pcall(tonumber, obj, base)
	if not success or not n then
		typeError('integer', type(obj))
	elseif n % 1 ~= 0 then
		typeError('integer', n)
	elseif mn and n < mn then
		typeError('minimum ' .. mn, n)
	elseif mx and n > mx then
		typeError('maximum ' .. mx, n)
	end
	return n
end

local function checkCallable(obj)
	local t = type(obj)
	if t == 'function' then
		return obj
	end
	local meta = getmetatable(obj)
	if meta and type(meta.__call) == 'function' then
		return obj
	end
	typeError('callable', t)
end

local function checkSnowflake(obj)
	local t = type(obj)
	if t == 'string' and tonumber(obj) then
		return obj
	elseif t == 'number' and obj < 2^32 then
		return string.format('%i', obj)
	elseif t == 'table' then
		return checkSnowflake(obj.id)
	end
	typeError('snowflake', t)
end

return {
	checkType = checkType,
	checkValue = checkValue,
	checkNumber = checkNumber,
	checkInteger = checkInteger,
	checkCallable = checkCallable,
	checkSnowflake = checkSnowflake,
}