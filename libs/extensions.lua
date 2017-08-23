local sort, concat = table.sort, table.concat
local insert, remove = table.insert, table.remove
local byte, char = string.byte, string.char
local gmatch, match = string.gmatch, string.match
local rep, find, sub = string.rep, string.find, string.sub
local min, max, random = math.min, math.max, math.random
local ceil, floor = math.ceil, math.floor

--[[
@module extensions

Various extensions to the Lua standard library. These are not loaded into the
global modules by default. To do this, call the module (eg: `extensions()`) or
an individual sub-module (eg: `extensions.table()`).
]]

local table = {}

--[[
@func table.count
@param tbl: table
@ret number

Returns the total number of elements in a table. This uses the global `pairs`
function and by default respects any `__pairs` metamethods.
]]
function table.count(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n = n + 1
	end
	return n
end

--[[
@func table.deepcount
@param tbl: table
@ret number

Returns the total number of elements in a table, recursively. If a table is
encountered, it is recursively counted instead of being directly added to the
total count.  This uses the global `pairs` function and by default respects
any `__pairs` metamethods.
]]
function table.deepcount(tbl)
	local n = 0
	for _, v in pairs(tbl) do
		n = type(v) == 'table' and n + table.deepcount(tbl) or n + 1
	end
	return n
end

--[[
@func table.copy
@param tbl: table
@ret table

Returns a copy of the original table, one layer deep.
]]
function table.copy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = v
	end
	return ret
end

--[[
@func table.deepcopy
@param tbl: table
@ret table

Returns a copy of the original table, recursively. If a table is encountered,
it is resursively deep-copied. Metatables are not copied.
]]
function table.deepcopy(tbl)
	local ret = {}
	for k, v in pairs(tbl) do
		ret[k] = type(v) == 'table' and table.deepcopy(v) or v
	end
	return ret
end

--[[
@func table.reverse
@param tbl: table

Reversed the elements of an array-like table in place.
]]
function table.reverse(tbl)
	for i = 1, #tbl do
		insert(tbl, i, remove(tbl))
	end
end

--[[
@func table.reversed
@param tbl: table
@ret table

Returns a copy of an array-like table with its elements in reverse order. The
original table remains unchanged.
]]
function table.reversed(tbl)
	local ret = {}
	for i = #tbl, 1, -1 do
		insert(ret, tbl[i])
	end
	return ret
end

--[[
@func table.keys
@param tbl: table
@ret table

Returns a new array-like table where all of its values are the keys of the
original table.
]]
function table.keys(tbl)
	local ret = {}
	for k in pairs(tbl) do
		insert(ret, k)
	end
	return ret
end

--[[
@func table.keys
@param tbl: table
@ret table

Returns a new array-like table where all of its values are the values of the
original table.
]]
function table.values(tbl)
	local ret = {}
	for _, v in pairs(tbl) do
		insert(ret, v)
	end
	return ret
end

--[[
@func table.randomipair
@param tbl: table
@ret number, *

Returns a random (index, value) pair from an array-like table.
]]
function table.randomipair(tbl)
	local i = random(#tbl)
	return i, tbl[i]
end

--[[
@func table.randompair
@param tbl: table
@ret *, *

Returns a random (key, value) pair from a dictionary-like table.
]]
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

--[[
@func table.sorted
@param tbl: table
@param fn: function
@ret table

Returns a copy of an array-like table sorted using Lua's `table.sort`.
]]
function table.sorted(tbl, fn)
	local ret = {}
	for i, v in ipairs(tbl) do
		ret[i] = v
	end
	sort(ret, fn)
	return ret
end

--[[
@func table.search
@param tbl: table
@param value: *
@ret *

Iterates through a table until it finds a value that is equal to `value`
according to the `==` operator. The key is returned if a match is found.
]]
function table.search(tbl, value)
	for k, v in pairs(tbl) do
		if v == value then
			return k
		end
	end
	return nil
end

--[[
@func table.slice
@param tbl: table
@param [start]: number
@param [stop]: number
@param [step]: number
@ret table

Returns a new table that is a slice of the original, defined by the start and
stop bounds and the step size. Default start, stop, and step values are
1, #tbl, and 1, respectively.
]]
function table.slice(tbl, start, stop, step)
	local ret = {}
	for i = start or 1, stop or #tbl, step or 1 do
		insert(ret, tbl[i])
	end
	return ret
end

local string = {}

--[[
@func string.split
@param str: string
@param [delim]: string
@ret table

Splits a string into a table of specifically delimited sub-strings. If the
delimiter is omitted or empty, the string is split into a table of characters.
]]
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

--[[
@func string.trim
@param str: string
@ret string

Returns a new string with all whitespace removed from the left and right sides
of the original string.
]]
function string.trim(str)
	return match(str, '^%s*(.-)%s*$')
end

--[[
@func string.pad
@param str: string
@param len: number
@param [align]: string
@param [pattern]: string
@ret string

Returns a new string that is padded up to the desired length. The alignment,
either `left`, `right`, or `center` with `left` being the default, defines the
placement of the original string. The default patter is a single space.
]]
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

--[[
@func string.startswith
@param str: string
@param pattern: string
@param [plain]: boolean
@ret boolean

Returns whether a string starts swith a specified sub-string or pattern. The
`plain` parameter is the same as that used in Lua's `string.find`.
]]
function string.startswith(str, pattern, plain)
	local start = 1
	return find(str, pattern, start, plain) == start
end

--[[
@func string.endswith
@param str: string
@param pattern: string
@param [plain]: boolean
@ret boolean

Returns whether a string ends swith a specified sub-string or pattern. The
`plain` parameter is the same as that used in Lua's `string.find`.
]]
function string.endswith(str, pattern, plain)
	local start = #str - #pattern + 1
	return find(str, pattern, start, plain) == start
end

--[[
@func string.levenshtein
@param str1: string
@param str2: string

Returns the Levenshtein distance between two strings. A higher number indicates
a greter distance.
]]
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

--[[
@func string.random
@param len: number
@param [min]: number
@param [max]: number

Returns a string of random characters with the specified length. If provided,
the min and max bounds cannot be outside 0 to 255. Use 32 to 126 for printable
ASCII characters.
]]
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

--[[
@func math.clamp
@param n: number
@param min: number
@param max: number

Returns a number that is at least as small as the minimum value and at most as
large as the maximum value, inclusively. If the original number is already with
the bounds, the same number is returned.
]]
function math.clamp(n, minValue, maxValue)
	return min(max(n, minValue), maxValue)
end

--[[
@func math.round
@param n: number
@param [digits]: number

Returns a number that is rounded to the nearest defined digit. The nearest
integer is returned if the digit is omitted. Negative values can be used for
higher order places.
]]
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
