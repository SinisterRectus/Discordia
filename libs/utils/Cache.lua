local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Cache = require('class')('Cache')

function Cache:__init(constructor, parent)
	self._count = 0
	self._parent = parent
	self._constructor = constructor
	self._objects = {}
end

function Cache:__tostring()
	return format('%s[%s]', self.__name, self._constructor.__name)
end

function Cache:_add(obj)
	self._objects[obj.id] = obj
	self._count = self._count + 1
	return obj
end

function Cache:_remove(obj)
	self._objects[obj.id] = nil
	self._count = self._count - 1
	return obj
end

function Cache:get(id)
	return self._objects[id]
end

function Cache:has(id)
	return self._objects[id] ~= nil
end

function Cache:add(obj)
	local old = self._objects[obj.id]
	if old then
		return nil
	else
		return self:_add(obj)
	end
end

function Cache:delete(id)
	local old = self._objects[id]
	if old then
		return self:_remove(old)
	else
		return nil
	end
end

local function parseData(data) -- TODO: maybe change error calls to return nil, err
	if data.__class then
		return error('data already has a class', 2)
	end
	local id = data.id or data.user and data.user.id
	if not id then
		return error('data does not have an id', 2)
	end
	return id
end

function Cache:insert(data, update)

	local id = parseData(data)
	if not id then return end

	local old = self._objects[id]

	if old then
		if update then
			old:_load(data)
		end
		return old
	else
		local obj = self._constructor(data, self._parent)
		return self:_add(obj)
	end

end

function Cache:remove(data, update)

	local id = parseData(data)
	if not id then return end

	local old = self._objects[id]

	if old then
		if update then
			old:_load(data)
		end
		return self:_remove(old)
	else
		return self._constructor(data, self._parent)
	end

end

function Cache:merge(array, update)
	if update then
		local updated = {}
		for _, data in ipairs(array) do
			local id = parseData(data)
			if id then
				updated[id] = true
				self:insert(data, true)
			end
		end
		for obj in self:iter() do
			local id = obj.id
			if not updated[id] then
				self:delete(id)
			end
		end
	else
		for _, data in ipairs(array) do
			self:insert(data)
		end
	end
end

function Cache:find(predicate)
	for obj in self:iter() do
		if predicate(obj) then
			return obj
		end
	end
	return nil
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

function Cache:iter()
	local objects, id, obj = self._objects
	return function()
		id, obj = next(objects, id)
		return obj
	end
end

function Cache:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

-- TODO: keys/values rows/columns methods

return Cache
