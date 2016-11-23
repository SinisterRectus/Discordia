local random = math.random
local insert, remove, sort = table.insert, table.remove, table.sort
local gmatch, match = string.gmatch, string.match
local format, rep = string.format, string.rep
local min, max = math.min, math.max
local ceil, floor = math.ceil, math.floor

-- globals --

function _G.printf(...)
	return print(format(...))
end

-- table --

function table.count(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n = n + 1
	end
	return n
end

function table.deepcount(tbl)
	local n = 0
	for _, v in pairs(tbl) do
		n = type(v) == 'table' and n + table.deepcount(v) or n + 1
	end
	return n
end

function table.find(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then return k end
	end
end

function table.reverse(tbl)
	for i = 1, #tbl do
		insert(tbl, i, remove(tbl))
	end
end

function table.reversed(tbl)
	local ret = {}
	for i = #tbl, 1, -1 do
		insert(ret, tbl[i])
	end
	return ret
end

function table.copy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = v
	end
	return new
end

function table.deepcopy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = type(v) == 'table' and table.deepcopy(v) or v
	end
	return new
end

function table.keys(tbl)
	local keys = {}
	for k in pairs(tbl) do
		insert(keys, k)
	end
	return keys
end

function table.values(tbl)
	local values = {}
	for _, v in pairs(tbl) do
		insert(values, v)
	end
	return values
end

function table.hash(tbl, key)
	for i, v in ipairs(tbl) do
		tbl[v[key]] = v
		tbl[i] = nil
	end
end

function table.randomipair(tbl)
	local i = random(#tbl)
	return i, tbl[i]
end

function table.randompair(tbl)
	local rand = random(table.count(tbl))
	local n = 0
	for k, v in pairs(tbl) do
		n = n + 1
		if n == rand then
			return k, v
		end
	end
end

function table.sorted(tbl, fn)
	local ret = {}
	for i, v in ipairs(tbl) do
		ret[i] = v
	end
	sort(ret, fn)
	return ret
end

function table.transposed(tbl)
	local ret = {}
	for _, row in ipairs(tbl) do
		for i, element in ipairs(row) do
			local column = ret[i] or {}
			insert(column, element)
			ret[i] = column
		end
	end
	return ret
end

function table.slice(tbl, start, stop, step)
	local ret = {}
	for i = start or 1, stop or #tbl, step or 1 do
		insert(ret, tbl[i])
	end
	return ret
end

-- string --

function string.startsWith(str, pat)
	return ((str:sub(1, pat:len()) ==pat and true) or false)
end

function string.split(str, delim)
	if delim and delim ~= '' then
		local words = {}
		for word in gmatch(str .. delim, '(.-)' .. delim) do
			insert(words, word)
		end
		return words
	else
		local chars = {}
		for char in gmatch(str, '.') do
			insert(chars, char)
		end
		return chars
	end
end

function string.trim(str)
	return match(str, '^%s*(.-)%s*$')
end

function string.padleft(str, len)
	return rep(' ', len - #str) .. str
end

function string.padright(str, len)
	return str .. rep(' ', len - #str)
end

function string.padcenter(str, len)
	local pad = 0.5 * (len - #str)
	return rep(' ', floor(pad)) .. str .. rep(' ', ceil(pad))
end

-- math --

function math.clamp(n, minValue, maxValue)
	return min(max(n, minValue), maxValue)
end

function math.round(n, i)
	local m = 10 ^ (i or 0)
	return floor(n * m + 0.5) / m
end
