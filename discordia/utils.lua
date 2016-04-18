local function camelify(obj)
	if type(obj) == 'string' then
		local str, count = obj:lower():gsub('_%l', string.upper):gsub('_', '')
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

local function split(str)
	local words = {}
	for word in string.gmatch(str, '%S+') do
		table.insert(words, word)
	end
	return words
end

local function clamp(n, min, max)
	return math.min(math.max(n, min), max)
end

return {
	camelify = camelify,
	split = split,
	clamp = clamp
}
