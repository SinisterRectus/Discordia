local Iterable = require('utils/Iterable')

local format = string.format

local Cache = require('class')('Cache', Iterable)

function Cache:__init(constructor, parent)
	self._constructor = constructor
	self._parent = parent
	self._objects = {}
	self._count = 0
end

function Cache:__tostring()
	return format('%s[%s]', self.__name, self._constructor.__name)
end

function Cache:__len()
	return self._count
end

function Cache:_insert(k, obj)
	self._objects[k] = obj
	self._count = self._count + 1
	return obj
end

function Cache:_remove(k, obj)
	self._objects[k] = nil
	self._count = self._count - 1
	return obj
end

function Cache:get(k)
	return self._objects[k]
end

-- function Cache:add(obj)
-- 	local k = obj:__hash()
-- 	local old = self._objects[k]
-- 	if old then
-- 		return nil
-- 	else
-- 		return self:_insert(k, obj)
-- 	end
-- end

function Cache:delete(k)
	local old = self._objects[k]
	if old then
		return self:_remove(k, old)
	else
		return nil
	end
end

local function hash(data)
	local meta = getmetatable(data)
	if not meta or meta.__jsontype ~= 'object' then
		return nil, 'data must be a json object'
	end
	if data.id then -- snowflakes
		return data.id
	elseif data.user then -- members
		return data.user.id
	elseif data.emoji then -- reactions
		return data.emoji.id or data.emoji.name
	elseif data.code then -- invites
		return data.code
	else
		return nil, 'json data could not be hashed'
	end
end

function Cache:insert(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return old
	else
		local obj = self._constructor(data, self._parent)
		return self:_insert(k, obj)
	end
end

function Cache:remove(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return self:_remove(k, old)
	else
		return self._constructor(data, self._parent)
	end
end

function Cache:merge(array, update)
	if update then
		local updated = {}
		for _, data in ipairs(array) do
			local obj = self:insert(data)
			updated[obj:__hash()] = true
		end
		for obj in self:iter() do
			local k = obj:__hash()
			if not updated[k] then
				self:delete(k)
			end
		end
	else
		for _, data in ipairs(array) do
			self:insert(data)
		end
	end
end

function Cache:iter()
	local objects, k, obj = self._objects
	return function()
		k, obj = next(objects, k)
		return obj
	end
end

-- TODO: keys/values rows/columns methods

return Cache
