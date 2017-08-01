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

function Iterable:get(k) -- objects must be hashable
	for obj in self:iter() do
		if obj:__hash() == k then
			return obj
		end
	end
	return nil
end

function Iterable:find(fn)
	for obj in self:iter() do
		if fn(obj) then
			return obj
		end
	end
	return nil
end

function Iterable:findAll(fn)
	return wrap(function()
		for obj in self:iter() do
			if fn(obj) then
				yield(obj)
			end
		end
	end)
end

function Iterable:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

function Iterable:toTable(fn)
	local ret = {}
	for obj in self:iter() do
		if not fn or fn(obj) then
			insert(ret, obj)
		end
	end
	return ret
end

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

local function compare(a, b)
	return a < b
end

local function sorter(a, b)
	local t1, t2 = type(a), type(b)
	if t1 == 'string' and t2 == 'string' then
		return (tonumber(a) or a:lower()) < (tonumber(b) or b:lower())
	elseif t1 == 'number' and t2 == 'number' then
		return a < b
	else
		local success, ret = pcall(compare)
		if success then
			return ret
		else
			return tostring(a) < tostring(b)
		end
	end
end

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
