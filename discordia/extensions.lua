local random = math.random
local insert, remove, sort, concat = table.insert, table.remove, table.sort, table.concat
local gmatch, match, byte, char = string.gmatch, string.match, string.byte, string.char
local format, rep, find, sub = string.format, string.rep, string.find, string.sub
local min, max = math.min, math.max
local ceil, floor = math.ceil, math.floor

-- globals --

function _G.printf(fmt, ...)
	return print(format(fmt, ...))
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

function string.split2(str, delim)
	if (not str) or (not delim) or str == "" or delim == "" then
		return {}
	else
		local current = 1
		local result = { }
		while true do
			local start, finish = find(str, delim, current)
			if start and finish then
				insert(result, sub(str, current, start-1))
				current = finish + 1
			else
				break
			end
		end
		insert(result, sub(str, current))
		return result
	end
end

function string.trim(str)
	return match(str, '^%s*(.-)%s*$')
end

function string.padleft(str, len, pattern)
	pattern = pattern or ' '
	return rep(pattern, len - #str) .. str
end

function string.padright(str, len, pattern)
	pattern = pattern or ' '
	return str .. rep(pattern, len - #str)
end

function string.padcenter(str, len, pattern)
	pattern = pattern or ' '
	local pad = 0.5 * (len - #str)
	return rep(pattern, floor(pad)) .. str .. rep(pattern, ceil(pad))
end

function string.startswith(str, pattern, plain)
	local start = 1
	return find(str, pattern, start, plain) == start
end

function string.endswith(str, pattern, plain)
	local start = #str - #pattern + 1
	return find(str, pattern, start, plain) == start
end

function string.levenshtein(str1, str2)

	if str1 == str2 then return 0 end

	local len1 = #str1
	local len2 = #str2

	if len1 == 0 then
		return len2
	elseif len2 == 0 then
		return len1
	end

	local matrix = {}
	for i = 0, len1 do
		matrix[i] = {[0] = i}
	end
	for j = 0, len2 do
		matrix[0][j] = j
	end

	for i = 1, len1 do
		for j = 1, len2 do
			local cost = byte(str1, i) == byte(str2, j) and 0 or 1
  			matrix[i][j] = min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end

	return matrix[len1][len2]

end

function string.random(len, minValue, maxValue)
	local ret = {}
	minValue = minValue or 0
	maxValue = maxValue or 255
	for _ = 1, len do
		insert(ret, char(random(minValue, maxValue)))
	end
	return concat(ret)
end

-- math --

function math.clamp(n, minValue, maxValue)
	return min(max(n, minValue), maxValue)
end

function math.round(n, i)
	local m = 10 ^ (i or 0)
	return floor(n * m + 0.5) / m
end
