--[=[
@c SecondaryCache x Iterable
@mt mem
@d Iterable class that wraps another cache. Objects added to or removed from a
secondary cache are also automatically added to or removed from the primary
cache that it wraps.
]=]

local Iterable = require('iterables/Iterable')

local SecondaryCache = require('class')('SecondaryCache', Iterable)

function SecondaryCache:__init(array, primary)
	local objects = {}
	for _, data in ipairs(array) do
		local obj = primary:_insert(data)
		objects[obj:__hash()] = obj
	end
	self._count = #array
	self._objects = objects
	self._primary = primary
end

function SecondaryCache:__pairs()
	return next, self._objects
end

function SecondaryCache:__len()
	return self._count
end

function SecondaryCache:_insert(data)
	local obj = self._primary:_insert(data)
	local k = obj:__hash()
	if not self._objects[k] then
		self._objects[k] = obj
		self._count = self._count + 1
	end
	return obj
end

function SecondaryCache:_remove(data)
	local obj = self._primary:_insert(data) -- yes, this is correct
	local k = obj:__hash()
	if self._objects[k] then
		self._objects[k] = nil
		self._count = self._count - 1
	end
	return obj
end

--[=[
@m get
@p k *
@r *
@d Returns an individual object by key, where the key should match the result of
calling `__hash` on the contained objects. Unlike the default version, this
method operates with O(1) complexity.
]=]
function SecondaryCache:get(k)
	return self._objects[k]
end

--[=[
@m iter
@r function
@d Returns an iterator that returns all contained objects. The order of the objects
is not guaranteed.
]=]
function SecondaryCache:iter()
	local objects, k, obj = self._objects
	return function()
		k, obj = next(objects, k)
		return obj
	end
end

return SecondaryCache
