local class = require('class')

local CompoundCache = class('CompoundCache')

function CompoundCache:__init(constructor, client)
	self._constructor = assert(constructor)
	self._client = assert(client)
	self._objects = {}
end

function CompoundCache:get(k1, k2)
	return self._objects[k1] and self._objects[k1][k2]
end

function CompoundCache:set(k1, k2, obj)
	self._objects[k1] = self._objects[k1] or {}
	self._objects[k1][k2] = assert(obj)
end

function CompoundCache:delete(k1, k2)
	if not self._objects[k1] then return end
	self._objects[k1][k2] = nil
	if not next(self._objects[k1]) then
		self._objects[k1] = nil
	end
end

function CompoundCache:update(k1, k2, data)
	local obj = self:get(k1, k2)
	if obj then
		obj:__init(data, self._client)
	else
		obj = self._constructor(data, self._client)
		self:set(k1, k2, obj)
	end
	return obj
end

return CompoundCache
