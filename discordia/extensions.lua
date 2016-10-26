-- globals --

function _G.printf(...)
	return print(string.format(...))
end

-- table --

function table.count(tbl)
	local n = 0
	for k, v in pairs(tbl) do
		n = n + 1
	end
	return n
end

function table.copy(from, deepCopy)
	if type(from) == "table" then
		local to = {}
		for k, v in pairs(from) do
			if deepCopy and type(v) == "table" then to[k] = table.copy(v)
			else to[k] = v
			end
		end
		return to
	end
end

function table.find(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
end

function table.clear(t)
	for i, v in pairs(t) do
		t[i] = nil
	end
end

function table.contains(t, what, member) --member is optional
	assert(type(t) == "table", "table.contains: wrong argument types (<table> expected for t)")
	for i, v in pairs(t) do
		if member and v[member] == what or v == what then return i, v end
	end
end

function table.reverse(tbl)
	for i = 1, #tbl do
		table.insert(tbl, i, table.remove(tbl))
	end
end

function table.copy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = v
	end
	return new
end

function table.copy(from, deepCopy)
	if type(from) == "table" then
		local to = {}
		for k, v in pairs(from) do
			if deepCopy and type(v) == "table" then to[k] = table.copy(v)
			else to[k] = v
			end
		end
		return to
	end
end

function table.keys(tbl)
	local keys = {}
	for k in pairs(tbl) do
		table.insert(keys, k)
	end
	return keys
end

function table.values(tbl)
	local values = {}
	for _, v in pairs(tbl) do
		table.insert(values, v)
	end
	return values
end

function table.randomipair(tbl)
	local i = math.random(#tbl)
	return i, tbl[i]
end

function table.randompair(tbl)
	local rand = math.random(table.count(tbl))
	local n = 0
	for k, v in pairs(tbl) do
		n = n + 1
		if n == rand then
			return k, v
		end
	end
end

-- string --

function string.split(str, delim)
	local words = {}
	for word in string.gmatch(str .. delim, '(.-)' .. delim) do
		table.insert(words, word)
	end
	return words
end

function string.totable(str)
	local chars = {}
	for char in string.gmatch(str, '.') do
		table.insert(chars, char)
	end
	return chars
end

-- math --

function math.clamp(n, min, max)
	return math.min(math.max(n, min), max)
end

function math.round(n, i)
	local m = 10^(i or 0)
	return math.floor(n * m + 0.5) / m
end
