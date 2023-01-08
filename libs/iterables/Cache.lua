--[=[
@c Cache x Iterable
@mt mem
@d Iterable class that holds references to Discordia Class objects in no particular order.
]=]

local json = require('json')
local Iterable = require('iterables/Iterable')

local null = json.null

local Cache = require('class')('Cache', Iterable)

local meta = {__mode = 'v'}

function Cache:__init(array, constructor, parent)
	local objects = {}
	for _, data in ipairs(array) do
		local obj = constructor(data, parent)
		objects[obj:__hash()] = obj
	end
	self._count = #array
	self._objects = objects
	self._constructor = constructor
	self._parent = parent
	self._deleted = setmetatable({}, meta)
end

function Cache:__pairs()
	return next, self._objects
end

function Cache:__len()
	return self._count
end

local function insert(self, k, obj)
	self._objects[k] = obj
	self._count = self._count + 1
	return obj
end

local function remove(self, k, obj)
	self._objects[k] = nil
	self._deleted[k] = obj
	self._count = self._count - 1
	return obj
end

local function hash(data)
	-- local meta = getmetatable(data) -- debug
	-- assert(meta and meta.__jsontype == 'object') -- debug
	if data.id then -- snowflakes
		return data.id
	elseif data.user then -- members
		return data.user.id
	elseif data.emoji then -- reactions
		return data.emoji.id ~= null and data.emoji.id or data.emoji.name
	elseif data.code then -- invites
		return data.code
	else
		return nil, 'json data could not be hashed'
	end
end

function Cache:_insert(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return old
	elseif self._deleted[k] then
		return insert(self, k, self._deleted[k])
	else
		local obj = self._constructor(data, self._parent)
		return insert(self, k, obj)
	end
end

function Cache:_remove(data)
	local k = assert(hash(data))
	local old = self._objects[k]
	if old then
		old:_load(data)
		return remove(self, k, old)
	elseif self._deleted[k] then
		return self._deleted[k]
	else
		return self._constructor(data, self._parent)
	end
end

function Cache:_delete(k)
	local old = self._objects[k]
	if old then
		return remove(self, k, old)
	elseif self._deleted[k] then
		return self._deleted[k]
	else
		return nil
	end
end

function Cache:_load(array, update)
	if update then
		local updated = {}
		for _, data in ipairs(array) do
			local obj = self:_insert(data)
			updated[obj:__hash()] = true
		end
		for obj in self:iter() do
			local k = obj:__hash()
			if not updated[k] then
				self:_delete(k)
			end
		end
	else
		for _, data in ipairs(array) do
			self:_insert(data)
		end
	end
end

--[=[
@m get
@p k *
@r *
@d Returns an individual object by key, where the key should match the result of
calling `__hash` on the contained objects. Unlike Iterable:get, this
method operates with O(1) complexity.
]=]
function Cache:get(k)
	return self._objects[k]
end

--[=[
@m iter
@r function
@d Returns an iterator that returns all contained objects. The order of the objects
is not guaranteed.
]=]
function Cache:iter()
	local objects, k, obj = self._objects, nil, nil
	return function()
		k, obj = next(objects, k)
		return obj
	end
end

return Cache
