local insert = table.insert
local format = string.format
local warning = console.warning
local wrap, yield = coroutine.wrap, coroutine.yield

local Cache, get = class('Cache')

function Cache:__init(array, constructor, key, parent)
	self._count = #array
	for i = 1, self._count do
		local obj = constructor(array[i], parent)
		array[obj[key]] = obj
		array[i] = nil
	end
	self._key = key
	self._parent = parent
	self._objects = array
	self._constructor = constructor
end

get('count', '_count', 'number')

function Cache:__tostring()
	return format('%s[%s]', self.__name, self._constructor.__name)
end

function Cache:_add(obj)
	self._objects[obj[self._key]] = obj
	self._count = self._count + 1
end

function Cache:_remove(obj)
	self._objects[obj[self._key]] = nil
	self._count = self._count - 1
end

function Cache:new(data)
	local new = self._constructor(data, self._parent)
	local old = self._objects[new[self._key]]
	if new == old then
		return old -- prevents double-caching HTTP and WS objects
	else
		self:_add(new)
		return new
	end
end

function Cache:merge(array)
	local key = self._key
	local parent = self._parent
	local objects = self._objects
	local constructor = self._constructor
	for _, data in ipairs(array) do
		local obj = constructor(data, parent)
		if not self:has(obj) then self:_add(obj) end
	end
end

function Cache:add(obj)
	if obj.__class ~= self._constructor then
		warning(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if self:has(obj) then
		warning('Object to add already cached: ' .. tostring(obj))
		return false
	end
	return self:_add(obj)
end

function Cache:remove(obj)
	if obj.__class ~= self._constructor then
		warning(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if not self:has(obj) then
		warning('Object to remove not found: ' .. tostring(obj))
		return false
	end
	return self:_remove(obj)
end

function Cache:has(obj)
	local cached = self._objects[obj[self._key]]
	return cached == obj
end

function Cache:iter()
	local objects, k, v = self._objects
	return function()
		k, v = next(objects, k)
		return v
	end
end

function Cache:get(key, value) -- use find for explicit obj[key] == nil
	if value == nil then
		return self._objects[key]
	elseif key == self._key then
		return self._objects[value]
	elseif key ~= nil then
		for obj in self:iter() do
			if obj[key] == value then
				return obj
			end
		end
	end
end

function Cache:getAll(key, value)
	if key == nil and value == nil then return self:iter() end
	return wrap(function()
		for obj in self:iter() do
			if obj[key] == value then
				yield(obj)
			end
		end
	end)
end

function Cache:find(predicate)
	for obj in self:iter() do
		if predicate(obj) then
			return obj
		end
	end
end

function Cache:findAll(predicate)
	return wrap(function()
		for obj in self:iter() do
			if predicate(obj) then
				yield(obj)
			end
		end
	end)
end

function Cache:keys()
	local key = self._key
	local keys = {}
	for obj in self:iter() do
		insert(keys, obj[key])
	end
	return keys
end

function Cache:values()
	local values = {}
	for obj in self:iter() do
		insert(values, obj)
	end
	return values
end

return Cache
