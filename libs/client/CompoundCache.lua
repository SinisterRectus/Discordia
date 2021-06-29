local class = require('class')

local insert = table.insert

local meta = {__mode = 'v'}

local CompoundCache = class('CompoundCache')

function CompoundCache:__init(constructor, client, weak)
	self._constructor = assert(constructor)
	self._client = assert(client)
	self._objects = {}
	self._weak = weak
end

function CompoundCache:get(k1, k2)
	return self._objects[k1] and self._objects[k1][k2]
end

function CompoundCache:set(k1, k2, obj)
	self._objects[k1] = self._objects[k1] or (self._weak and setmetatable({}, meta) or {})
	self._objects[k1][k2] = assert(obj)
end

function CompoundCache:delete(k1, k2)
	if not self._objects[k1] then return end
	if k2 then
		self._objects[k1][k2] = nil
		if not next(self._objects[k1]) then
			self._objects[k1] = nil
		end
	else
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

function CompoundCache:toArray(k1)
	local ret = {}
	local objects = self._objects[k1]
	if objects then
		for _, v in pairs(objects) do
			insert(ret, v)
		end
	end
	return ret
end

return CompoundCache
