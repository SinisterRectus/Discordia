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

return {
	camelify = camelify
}
