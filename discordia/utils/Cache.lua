local insert = table.insert
local format = string.format
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

function Cache:new(data)
	local new = self.constructor(data, self.parent)
	local old = self.objects[new[self.key]]
	if new == old then
		return old -- need to make sure HTTP obj is the same as WS object
	else
		self:add(new)
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
		if not self:has(obj) then self:add(obj) end
	end
end

function Cache:add(obj)
	if not obj.__class == self.constructor then
		warning('Attempted to cache invalid object type: ' .. tostring(obj))
		return false
	end
	if self:has(obj) then
		warning('Object to add already cached: ' .. tostring(obj))
		return false
	end
	self.objects[obj[self.key]] = obj
	self.count = self.count + 1
	return true
end

function Cache:remove(obj)
	if not self:has(obj) then
		warning('Object to remove not found: ' .. tostring(obj))
		return false
	end
	self.objects[obj[self.key]] = nil
	self.count = self.count - 1
	return true
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

function Cache:get(key, value)
	if not value then
		value = key
		key = self.key
	end
	if key == self.key then
		return self.objects[value]
	else
		for obj in self:iter() do
			if obj[key] == value then
				return obj
			end
		end
	end
end

function Cache:find(key, predicate)
	for obj in self:iter() do
		if predicate(obj[key]) then
			return obj
		end
	end
end

function Cache:getAll(key, value)
	return wrap(function()
		for obj in self:iter() do
			if obj[key] == value then
				yield(obj)
			end
		end
	end)
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
	local ret = {}
	for obj in self:iter() do
		insert(ret, obj[self.key])
	end
	return ret
end

function Cache:values()
	local ret = {}
	for obj in self:iter() do
		insert(ret, obj)
	end
	return ret
end

return Cache
