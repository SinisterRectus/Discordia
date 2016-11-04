local format = string.format
local insert, sort = table.insert, table.sort
local wrap, yield = coroutine.wrap, coroutine.yield

local Cache, property, method = class('Cache')
Cache.__description = "Enhanced Lua table that is used to store Discord objects of the same type."

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

function Cache:__tostring()
	return format('%s[%s]', self.__name, self._constructor.__name)
end

function Cache:_add(obj)
	if not obj[self._key] then -- debug
		p(self._key)
		for k, v in pairs(obj) do
			print(k, v)
		end
	end
	self._objects[obj[self._key]] = obj
	self._count = self._count + 1
end

function Cache:_remove(obj)
	self._objects[obj[self._key]] = nil
	self._count = self._count - 1
end

local function new(self, data)
	local new = self._constructor(data, self._parent)
	local old = self._objects[new[self._key]]
	if new == old then
		return old -- prevents double-caching HTTP and WS objects
	else
		self:_add(new)
		return new
	end
end

local function merge(self, array)
	local key = self._key
	local parent = self._parent
	local objects = self._objects
	local constructor = self._constructor
	for _, data in ipairs(array) do
		local obj = constructor(data, parent)
		if not self:has(obj) then self:_add(obj) end
	end
end

local function add(self, obj)
	if obj.__name ~= self._constructor.__name then
		error(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if self:has(obj) then
		return false
	end
	return self:_add(obj)
end

local function remove(self, obj)
	if obj.__name ~= self._constructor.__name then
		error(format('Invalid object type %q for %s', obj.__name, self))
		return false
	end
	if not self:has(obj) then
		return false
	end
	return self:_remove(obj)
end

local function has(self, obj)
	local cached = self._objects[obj[self._key]]
	return cached == obj
end

local function iter(self)
	local objects, k, v = self._objects
	return function()
		k, v = next(objects, k)
		return v
	end
end

local function get(self, key, value)
end

local function getAll(self, key, value)
	if key == nil and value == nil then return self:iter() end
	return wrap(function()
		for obj in self:iter() do
			if obj[key] == value then
				yield(obj)
			end
		end
	end)
end

local function find(self, predicate)
	for obj in self:iter() do
		if predicate(obj) then
			return obj
		end
	end
end

local function findAll(self, predicate)
	return wrap(function()
		for obj in self:iter() do
			if predicate(obj) then
				yield(obj)
			end
		end
	end)
end

local function keys(self)
	local key = self._key
	local keys = {}
	for obj in self:iter() do
		insert(keys, obj[key])
	end
	sort(keys)
	return keys
end

local function values(self)
	local values = {}
	for obj in self:iter() do
		insert(values, obj)
	end
	return values
end

property('count', '_count', nil, 'number', "How many objects are cached")

method('new', new, 'data', "Adds a new Discord object from a JSON data table and returns the object.")
method('merge', merge, 'array', "Adds many new Discord object from an array of JSON data tables.")
method('add', add, 'obj', "Adds an object to the cache. Must match the defined type.")
method('remove', remove, 'obj', "Remove an object from the cache. Must match the defined type.")
method('has', has, 'obj', "Returns a boolean indicating whether the cache contains the specified object.")
method('iter', iter, nil, "Returns an iterator for the objects in the queue. Order is not guaranteed.")
method('get', get, '[key,] value', "Returns the first object matching the provided (key, value) pair.")
method('getAll', get, '[key, value]', "Returns an iterator for all objects that match the (key, value) pair.")
method('find', find, 'predicate', "Returns the first object found that satisfies a predicate.")
method('findAll', findAll, 'predicate', "Returns an iterator for all objects that satisfy a predicate.")
method('keys', keys, nil, "Returns an array-like Lua table of all of the cached objects' keys, sorted by key.")
method('values', values, nil, "Returns an array-like Lua table of all of the cached objects, sorted by key.")

return Cache
