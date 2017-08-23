local random = math.random
local wrap, yield = coroutine.wrap, coroutine.yield
local insert, sort, pack = table.insert, table.sort, table.pack

local Iterable = require('class')('Iterable')

--[[
@abc Iterable

Abstract base class that defines the base methods and/or properties for a
general purpose data structure with features that are better suited for an
object-oriented environment.

Note: All sub-classes must implement their own `__init` and `iter` methods.
Additionally, more efficient versions of `__len` and `get` methods can be
redefined in sub-classes.
]]

function Iterable:__len()
	local n = 0
	for _ in self:iter() do
		n = n + 1
	end
	return n
end

--[[
@method get
@param k: *
@ret *

Returns an individual object by key, where the key should match the result of
calling `__hash` on the contained objects. Operates with up to O(n) complexity.
]]
function Iterable:get(k) -- objects must be hashable
	for obj in self:iter() do
		if obj:__hash() == k then
			return obj
		end
	end
	return nil
end

--[[
@method find
@param fn: function
@ret *

Returns the first object that satisfies a predicate.
]]
function Iterable:find(fn)
	for obj in self:iter() do
		if fn(obj) then
			return obj
		end
	end
	return nil
end

--[[
@method findAll
@param fn: function
@ret function

Returns an iterator that returns all objects that satisfy a predicate.
]]
function Iterable:findAll(fn)
	return wrap(function()
		for obj in self:iter() do
			if fn(obj) then
				yield(obj)
			end
		end
	end)
end

--[[
@method forEach
@param fn: function

Iterates through all objects and calls a function `fn` that takes the
objects as an argument.
]]
function Iterable:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

--[[
@method random
@ret *

Returns a random object that is contained in the iterable.
]]
function Iterable:random()
	local n = 1
	local rand = random(#self)
	for obj in self:iter() do
		if n == rand then
			return obj
		end
		n = n + 1
	end
end

--[[
@method count
@param fn: function
@ret number

Returns the amount of objects that satisfy a predicate.
]]
function Iterable:count(fn)
	local n = 0
	for _ in self:findAll(fn) do
		n = n + 1
	end
	return n
end

local function sorter(a, b)
	local t1, t2 = type(a), type(b)
	if t1 == 'string' then
		if t2 == 'string' then
			local n1 = tonumber(a)
			if n1 then
				local n2 = tonumber(b)
				if n2 then
					return n1 < n2
				end
			end
			return a:lower() < b:lower()
		elseif t2 == 'number' then
			local n1 = tonumber(a)
			if n1 then
				return n1 < b
			end
			return a:lower() < tostring(b)
		end
	elseif t1 == 'number' then
		if t2 == 'number' then
			return a < b
		elseif t2 == 'string' then
			local n2 = tonumber(b)
			if n2 then
				return a < n2
			end
			return tostring(a) < b:lower()
		end
	end
	local m1 = getmetatable(a)
	if m1 and m1.__lt then
		local m2 = getmetatable(b)
		if m2 and m2.__lt then
			return a < b
		end
	end
	return tostring(a) < tostring(b)
end

--[[
@method toTable
@param [sortBy]: string
@param [fn]: function
@ret table

Returns a table that contains references to all objects. If a `sortBy` string is
provided, then the table is sorted by that particular property. If a predicate
is provided, then only objects that satisfy it will be included.
]]
function Iterable:toTable(sortBy, fn)
	local ret = {}
	for obj in self:iter() do
		if not fn or fn(obj) then
			insert(ret, obj)
		end
	end
	if type(sortBy) == 'string' then
		sort(ret, function(a, b)
			return sorter(a[sortBy], b[sortBy])
		end)
	end
	return ret
end

--[[
@method select
@param ...: *
@ret table

Similarly to an SQL query, this returns a sorted Lua table of rows where each
row corresponds to each object in the iterable, and each value in the row is
selected from the objects according to the arguments provided.
]]
function Iterable:select(...)
	local rows = {}
	local keys = pack(...)
	for obj in self:iter() do
		local row = {}
		for i = 1, keys.n do
			row[i] = obj[keys[i]]
		end
		insert(rows, row)
	end
	sort(rows, function(a, b)
		for i = 1, keys.n do
			if a[i] ~= b[i] then
				return sorter(a[i], b[i])
			end
		end
	end)
	return rows
end

return Iterable
