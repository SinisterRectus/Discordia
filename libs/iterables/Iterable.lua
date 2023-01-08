--[=[
@c Iterable
@mt mem
@d Abstract base class that defines the base methods and properties for a
general purpose data structure with features that are better suited for an
object-oriented environment.

Note: All sub-classes should implement their own `__init` and `iter` methods and
all stored objects should have a `__hash` method.
]=]

local random = math.random
local insert, sort, pack, unpack = table.insert, table.sort, table.pack, table.unpack

local Iterable = require('class')('Iterable')

--[=[
@m __pairs
@r function
@d Defines the behavior of the `pairs` function. Returns an iterator that returns
a `key, value` pair, where `key` is the result of calling `__hash` on the `value`.
]=]
function Iterable:__pairs()
	local gen = self:iter()
	return function()
		local obj = gen()
		if not obj then
			return nil
		end
		return obj:__hash(), obj
	end
end

--[=[
@m __len
@r function
@d Defines the behavior of the `#` operator. Returns the total number of objects
stored in the iterable.
]=]
function Iterable:__len()
	local n = 0
	for _ in self:iter() do
		n = n + 1
	end
	return n
end

--[=[
@m get
@p k *
@r *
@d Returns an individual object by key, where the key should match the result of
calling `__hash` on the contained objects. Operates with up to O(n) complexity.
]=]
function Iterable:get(k) -- objects must be hashable
	for obj in self:iter() do
		if obj:__hash() == k then
			return obj
		end
	end
	return nil
end

--[=[
@m find
@p fn function
@r *
@d Returns the first object that satisfies a predicate.
]=]
function Iterable:find(fn)
	for obj in self:iter() do
		if fn(obj) then
			return obj
		end
	end
	return nil
end

--[=[
@m findAll
@p fn function
@r function
@d Returns an iterator that returns all objects that satisfy a predicate.
]=]
function Iterable:findAll(fn)
	local gen = self:iter()
	return function()
		while true do
			local obj = gen()
			if not obj then
				return nil
			end
			if fn(obj) then
				return obj
			end
		end
	end
end

--[=[
@m forEach
@p fn function
@r nil
@d Iterates through all objects and calls a function `fn` that takes the
objects as an argument.
]=]
function Iterable:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

--[=[
@m random
@r *
@d Returns a random object that is contained in the iterable.
]=]
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

--[=[
@m count
@op fn function
@r number
@d If a predicate is provided, this returns the number of objects in the iterable
that satisfy the predicate; otherwise, the total number of objects.
]=]
function Iterable:count(fn)
	if not fn then
		return self:__len()
	end
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

--[=[
@m toArray
@op sortBy string
@op fn function
@r table
@d Returns a sequentially-indexed table that contains references to all objects.
If a `sortBy` string is provided, then the table is sorted by that particular
property. If a predicate is provided, then only objects that satisfy it will
be included.
]=]
function Iterable:toArray(sortBy, fn)
	local t1 = type(sortBy)
	if t1 == 'string' then
		fn = type(fn) == 'function' and fn
	elseif t1 == 'function' then
		fn = sortBy
		sortBy = nil
	end
	local ret = {}
	for obj in self:iter() do
		if not fn or fn(obj) then
			insert(ret, obj)
		end
	end
	if sortBy then
		sort(ret, function(a, b)
			return sorter(a[sortBy], b[sortBy])
		end)
	end
	return ret
end

--[=[
@m select
@p ... string
@r table
@d Similarly to an SQL query, this returns a sorted Lua table of rows where each
row corresponds to each object in the iterable, and each value in the row is
selected from the objects according to the keys provided.
]=]
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
		return false
	end)
	return rows
end

--[=[
@m pick
@p ... string/function
@r function
@d This returns an iterator that, when called, returns the values from each
encountered object, picked by the provided keys. If a key is a string, the objects
are indexed with the string. If a key is a function, the function is called with
the object passed as its first argument.
]=]
function Iterable:pick(...)
	local keys = pack(...)
	local values = {}
	local n = keys.n
	local gen = self:iter()
	return function()
		local obj = gen()
		if not obj then
			return nil
		end
		for i = 1, n do
			local k = keys[i]
			if type(k) == 'function' then
				values[i] = k(obj)
			else
				values[i] = obj[k]
			end
		end
		return unpack(values, 1, n)
	end
end

return Iterable
