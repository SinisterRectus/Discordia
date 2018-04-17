--[[ NOTE:
These standard library extensions are NOT used in Discordia. They are here as a
convenience for those who wish to use them.

There are multiple ways to implement some of these commonly used functions.
Please pay attention to the implementations used here and make sure that they
match your expectations.

You may freely add to, remove, or edit any of the code here without any effect
on the rest of the library. If you do make changes, do be careful when sharing
your expectations with other users.

You can inject these extensions into the standard Lua global tables by
calling either the main module (ex: discordia.extensions()) or each sub-module
(ex: discordia.extensions.string())
]]

local sort, concat = table.sort, table.concat
local insert, remove = table.insert, table.remove
local byte, char = string.byte, string.char
local gmatch, match = string.gmatch, string.match
local rep, find, sub = string.rep, string.find, string.sub
local min, max, random = math.min, math.max, math.random
local ceil, floor = math.ceil, math.floor

local table = {}

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

function table.copy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = v
	end
	return ret
end

function table.deepcopy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = type(v) == 'table' and table.deepcopy(v) or v
	end
	return ret
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

function table.keys(tbl)
	local ret = {}
	for k in pairs(tbl) do
		insert(ret, k)
	end
	return ret
end

function table.values(tbl)
	local ret = {}
	for _, v in pairs(tbl) do
		insert(ret, v)
	end
	return ret
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

function table.search(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

function table.slice(tbl, start, stop, step)
	local ret = {}
	for i = start or 1, stop or #tbl, step or 1 do
		insert(ret, tbl[i])
	end
	return ret
end

local string = {}

function string.split(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in gmatch(str, '.') do
			insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = find(str, delim, n)
		if not i then break end
		insert(ret, sub(str, n, i - 1))
		n = j + 1
	end
	insert(ret, sub(str, n))
	return ret
end

function string.trim(str)
	return match(str, '^%s*(.-)%s*$')
end

function string.pad(str, len, align, pattern)
	pattern = pattern or ' '
	if align == 'right' then
		return rep(pattern, (len - #str) / #pattern) .. str
	elseif align == 'center' then
		local pad = 0.5 * (len - #str) / #pattern
		return rep(pattern, floor(pad)) .. str .. rep(pattern, ceil(pad))
	else -- left
		return str .. rep(pattern, (len - #str) / #pattern)
	end
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

function string.random(len, mn, mx)
	local ret = {}
	mn = mn or 0
	mx = mx or 255
	for _ = 1, len do
		insert(ret, char(random(mn, mx)))
	end
	return concat(ret)
end

local math = {}

function math.clamp(n, minValue, maxValue)
	return min(max(n, minValue), maxValue)
end

function math.round(n, i)
	local m = 10 ^ (i or 0)
	return floor(n * m + 0.5) / m
end

local ext = setmetatable({
	table = table,
	string = string,
	math = math,
}, {__call = function(self)
	for _, v in pairs(self) do
		v()
	end
end})

for n, m in pairs(ext) do
	setmetatable(m, {__call = function(self)
		for k, v in pairs(self) do
			_G[n][k] = v
		end
	end})
end

return ext
