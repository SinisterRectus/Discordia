local random = math.random
local wrap, yield = coroutine.wrap, coroutine.yield
local insert, sort, pack = table.insert, table.sort, table.pack

local Iterable = require('class')('Iterable')

--[[ NOTE:
- this is more of a mixin, without an initializer
- init and iter methods must be defined in each sub-class
- len and get can be redefined in any sub-class
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
]]
function Iterable:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

--[[
@method random
@ret *
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
@param fn: function
@ret table
]]
function Iterable:toTable(fn, sortBy)
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
