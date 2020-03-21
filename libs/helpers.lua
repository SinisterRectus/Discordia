local insert = table.insert
local format, byte, gsub = string.format, string.byte, string.gsub

local function toPercent(char)
	return format('%%%02X', byte(char))
end

local function urlEncode(obj)
	return (gsub(tostring(obj), '%W', toPercent))
end

local function attachQuery(url, query)
	for k, v in pairs(query) do
		insert(url, #url == 1 and '?' or '&')
		insert(url, urlEncode(k))
		insert(url, '=')
		insert(url, urlEncode(v))
	end
end

local function typeError(expected, received)
	return error(format('expected %s, received %s', expected, received), 2)
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

return {
	urlEncode = urlEncode,
	attachQuery = attachQuery,
	checkNumber = checkNumber,
}
