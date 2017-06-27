local Iterable = require('iterables/Iterable')

local format = string.format

local SecondaryCache = require('class')('SecondaryCache', Iterable)

function SecondaryCache:__init(array, primary)
	local objects = {}
	for _, data in ipairs(array) do
		local obj = primary:_insert(data)
		objects[obj:__hash()] = obj
	end
	self._objects = objects
	self._primary = primary
end

function SecondaryCache:__tostring()
	return format('%s[%s]', self.__name, self._primary._constructor.__name)
end

function SecondaryCache:_insert(data)
	local obj = self._primary:_insert(data)
	self._objects[obj:__hash()] = obj
	return obj
end

function SecondaryCache:_remove(data)
	local obj = self._primary:_insert(data) -- yes, this is correct
	self._objects[obj:__hash()] = nil
	return obj
end

function SecondaryCache:get(k)
	return self._objects[k]
end

function SecondaryCache:iter()
	local objects, k, obj = self._objects
	return function()
		k, obj = next(objects, k)
		return obj
	end
end

return SecondaryCache
