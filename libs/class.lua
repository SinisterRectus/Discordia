local format = string.format

local meta = {}
local names = {}
local classes = {}
local objects = setmetatable({}, {__mode = 'k'})

function meta:__call(...)
	local obj = setmetatable({}, self)
	objects[obj] = true
	obj:__init(...)
	return obj
end

function meta:__tostring()
	return 'class ' .. self.__name
end

local default = {}

function default:__tostring()
	return self.__name
end

function default:__hash()
	return self
end

local function isClass(cls)
	return classes[cls]
end

local function isObject(obj)
	return objects[obj]
end

local function isSubclass(sub, cls)
	if isClass(sub) and isClass(cls) then
		if sub == cls then
			return true
		else
			for _, base in ipairs(sub.__bases) do
				if isSubclass(base, cls) then
					return true
				end
			end
		end
	end
	return false
end

local function isInstance(obj, cls)
	return isObject(obj) and isSubclass(obj.__class, cls)
end

local function profile()
	local ret = setmetatable({}, {__index = function() return 0 end})
	for obj in pairs(objects) do
		local name = obj.__name
		ret[name] = ret[name] + 1
	end
	return ret
end

local types = {['string'] = true, ['number'] = true, ['boolean'] = true}

local function _getPrimitive(v)
	return types[type(v)] and v or v ~= nil and tostring(v) or nil
end

local function serialize(obj)
	if isObject(obj) then
		local ret = {}
		for k, v in pairs(obj.__getters) do
			ret[k] = _getPrimitive(v(obj))
		end
		return ret
	else
		return _getPrimitive(obj)
	end
end

local rawtype = type
local function type(obj)
	return isObject(obj) and obj.__name or rawtype(obj)
end

return setmetatable({

	classes = names,
	isClass = isClass,
	isObject = isObject,
	isSubclass = isSubclass,
	isInstance = isInstance,
	type = type,
	profile = profile,
	serialize = serialize,

}, {__call = function(_, name, ...)

	if names[name] then return error(format('Class %q already defined', name)) end

	local class = setmetatable({}, meta)
	classes[class] = true

	for k, v in pairs(default) do
		class[k] = v
	end

	local bases = {...}
	local getters = {}
	local setters = {}

	for _, base in ipairs(bases) do
		for k1, v1 in pairs(base) do
			class[k1] = v1
			for k2, v2 in pairs(base.__getters) do
				getters[k2] = v2
			end
			for k2, v2 in pairs(base.__setters) do
				setters[k2] = v2
			end
		end
	end

	class.__name = name
	class.__class = class
	class.__bases = bases
	class.__getters = getters
	class.__setters = setters

	local pool = {}
	local n = #pool

	function class:__index(k)
		if getters[k] then
			return getters[k](self)
		elseif pool[k] then
			return rawget(self, pool[k])
		else
			return class[k]
		end
	end

	function class:__newindex(k, v)
		if setters[k] then
			return setters[k](self, v)
		elseif class[k] or getters[k] then
			return error(format('Cannot overwrite protected property: %s.%s', name, k))
		elseif k:find('_', 1, true) ~= 1 then
			return error(format('Cannot write property to object without leading underscore: %s.%s', name, k))
		else
			if not pool[k] then
				n = n + 1
				pool[k] = n
			end
			return rawset(self, pool[k], v)
		end
	end

	names[name] = class

	return class, getters, setters

end})
