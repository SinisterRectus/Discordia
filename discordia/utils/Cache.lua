local insert = table.insert
local format = string.format
local warning = console.warning
local wrap, yield = coroutine.wrap, coroutine.yield

local Cache = class('Cache')

function Cache:__init(array, constructor, key, parent)
	self.count = #array
	for i = 1, self.count do
		local obj = constructor(array[i], parent)
		array[obj[key]] = obj
		array[i] = nil
	end
	self.key = key
	self.parent = parent
	self.objects = array
	self.constructor = constructor
end

function Cache:__tostring()
	return format('%s[%s]', self.__name, self.constructor.__name)
end

local function add(cache, obj)
	cache.objects[obj[cache.key]] = obj
	cache.count = cache.count + 1
	return true
end

local function remove(cache, obj)
	cache.objects[obj[cache.key]] = nil
	cache.count = cache.count - 1
	return true
end

function Cache:new(data)
	local new = self.constructor(data, self.parent)
	local old = self.objects[new[self.key]]
	if new == old then
		return old -- prevents double-caching HTTP and WS objects
	else
		add(self, new)
		return new
	end
end

function Cache:merge(array)
	local key = self.key
	local parent = self.parent
	local objects = self.objects
	local constructor = self.constructor
	for _, data in ipairs(array) do
		local obj = constructor(data, parent)
		if not self:has(obj) then add(self, obj) end
	end
end

function Cache:add(obj)
	if obj.__class ~= self.constructor then
		warning(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if self:has(obj) then
		warning('Object to add already cached: ' .. tostring(obj))
		return false
	end
	return add(self, obj)
end

function Cache:remove(obj)
	if obj.__class ~= self.constructor then
		warning(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if not self:has(obj) then
		warning('Object to remove not found: ' .. tostring(obj))
		return false
	end
	return remove(self, obj)
end

function Cache:has(obj)
	local cached = self.objects[obj[self.key]]
	return cached == obj
end

function Cache:iter()
	local objects, k, v = self.objects
	return function()
		k, v = next(objects, k)
		return v
	end
end

function Cache:get(key, value) -- use find for explicit obj[key] == nil
	if key and not value then
		return self.objects[key]
	elseif key == self.key then
		return self.objects[value]
	else
		for obj in self:iter() do
			if obj[key] == value then
				return obj
			end
		end
	end
end

function Cache:getAll(key, value) -- use filter to return a new cache
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

function Cache:filter(predicate)
	local cache = Cache({}, self.constructor, self.key, self.parent)
	for obj in self:iter() do
		if predicate(obj) then
			add(cache, obj)
		end
	end
	return cache
end

function Cache:keys()
	local key = self.key
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
