local format = string.format

local function typeError(expected, received)
	return error(format('expected %s, received %s', expected, received), 2)
end

local function checkType(expected, obj)
	local received = type(obj)
	if received ~= expected then
		return typeError(expected, received)
	end
	return obj
end

local function checkNumber(obj, base, int, mn, mx)
	local success, n = pcall(tonumber, obj, base)
	if not success or not n then
		return typeError('number', type(obj))
	end
	if int and n % 1 ~= 0 then
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

local function checkCallable(obj)
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

local function checkEnum(enum, obj)
	if type(obj) == 'string' then
		return enum[obj]
	else
		return enum(obj) and obj
	end
end

return {
	checkNumber = checkNumber,
	checkCallable = checkCallable,
	checkType = checkType,
	checkEnum = checkEnum,
}
