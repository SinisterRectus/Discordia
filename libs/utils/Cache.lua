local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Cache = require('class')('Cache')

function Cache:__init(constructor, parent)
	self._constructor = constructor
	self._parent = parent
	self._objects = {}
	self._count = 0
end

function Cache:__tostring()
	return format('%s[%s]', self.__name, self._constructor.__name)
end

function Cache:_add(obj)
	self._objects[obj:__hash()] = obj
	self._count = self._count + 1
	return obj
end

function Cache:_remove(obj)
	self._objects[obj:__hash()] = nil
	self._count = self._count - 1
	return obj
end

function Cache:get(k)
	return self._objects[k]
end

function Cache:has(k)
	return self._objects[k] ~= nil
end

function Cache:add(obj)
	local old = self._objects[obj:__hash()]
	if old then
		return nil
	else
		return self:_add(obj)
	end
end

function Cache:delete(k)
	local old = self._objects[k]
	if old then
		return self:_remove(old)
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
	elseif data.code then -- invites
		return data.code
	elseif data.user then -- members
		return data.user.id
	elseif data.emoji then -- reactions
		return data.emoji.id or data.emoji.name
	else
		return nil, 'json data could not be hashed'
	end
end

function Cache:insert(data, update)

	local k = assert(hash(data))
	local old = self._objects[k]

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

	local k = assert(hash(data))
	local old = self._objects[k]

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
			local id = hash(data)
			if id then
				updated[id] = true
				self:insert(data, true)
			end
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
	local objects, k, obj = self._objects
	return function()
		k, obj = next(objects, k)
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
