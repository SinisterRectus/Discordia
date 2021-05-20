local class = require('class')

local Cache = class('Cache')

function Cache:__init(constructor, client)
	self._constructor = assert(constructor)
	self._client = assert(client)
	self._objects = {}
end

function Cache:get(k)
	return self._objects[k]
end

function Cache:set(k, obj)
	self._objects[k] = assert(obj)
end

function Cache:delete(k)
	self._objects[k] = nil
end

function Cache:update(k, data)
	local obj = self:get(k)
	if obj then
		obj:__init(data, self._client)
	else
		obj = self._constructor(data, self._client)
		self:set(k, obj)
	end
	return obj
end

return Cache
