local checkCalls = true

local meta = {}
local names = {}
local classes = {}
local objects = setmetatable({}, {__mode = 'k'})

function meta:__index(k)
	return self.__methods[k]
end

function meta:__call(...)
	local obj = setmetatable({}, self.__methods)
	obj:__init(...)
	objects[obj] = true
	return obj
end

function meta:__tostring()
	return 'class: ' .. self.__name
end

local function isClass(cls)
	return classes[cls]
end

local function isObject(obj)
	return objects[obj]
end

local function isSubclass(sub, cls)
	if isClass(sub) and isClass(cls) then
		return sub == cls or isSubclass(sub.__base, cls)
	end
	return false
end

local function isInstance(obj, cls)
	return isObject(obj) and isSubclass(obj.__class, cls)
end

local function profile()
	local counts = {}
	for cls in pairs(classes) do
		counts[cls.__name] = 0
	end
	for obj in pairs(objects) do
		counts[obj.__name] = counts[obj.__name] + 1
	end
	return counts
end

local function mixin(target, source)
	for k, v in pairs(source) do
		target[k] = v
	end
end

local function isMember(class, fn)
	if not isClass(class) then return false end
	for _, v in pairs(class.__methods) do if v == fn then return true end end
	for _, v in pairs(class.__getters) do if v == fn then return true end end
	for _, v in pairs(class.__setters) do if v == fn then return true end end
	return isMember(class.__base, fn)
end

local function checkMember(class, level)
	local info = debug.getinfo(level, 'f')
	if not isMember(class, info.func) then
		error('cannot access private class property', level)
	end
end

return setmetatable({

	isClass = isClass,
	isObject = isObject,
	isSubclass = isSubclass,
	isInstance = isInstance,
	profile = profile,
	mixin = mixin,

}, {__call = function(_, name, base)

	assert(type(name) == 'string', 'name must be a string')
	assert(base == nil or isClass(base), 'base must be a class')
	assert(not names[name], 'class already defined')

	local class = setmetatable({}, meta)
	names[name] = true
	classes[class] = true

	local methods = {}
	local getters = {}
	local setters = {}

	local properties = setmetatable({}, {__call = function(self, k)
		if self[k] then
			return error('property already defined')
		end
		local n = 1
		for _ in pairs(self) do
			n = n + 1
		end
		self[k] = n
	end})

	if base then
		mixin(methods, base.__methods)
		mixin(getters, base.__getters)
		mixin(setters, base.__setters)
		mixin(properties, base.__properties)
	end

	class.__name = name
	class.__base = base
	class.__class = class
	class.__methods = methods
	class.__getters = getters
	class.__setters = setters
	class.__properties = properties

	function methods:__index(k)
		if getters[k] then
			return getters[k](self)
		elseif properties[k] then
			if checkCalls then checkMember(class, 3) end
			return rawget(self, properties[k])
		elseif class[k] ~= nil then
			return class[k]
		else
			return error('undefined class member')
		end
	end

	function methods:__newindex(k, v)
		if setters[k] then
			return setters[k](self, v)
		elseif not properties[k] then
			return error('undefined class property')
		else
			if checkCalls then checkMember(class, 3) end
			return rawset(self, properties[k], v)
		end
	end

	function methods:__tostring()
		local fn = methods.toString
		if fn then
			return self.__name .. ': ' .. fn(self)
		else
			return 'object: ' .. self.__name
		end
	end

	return class, properties, methods, getters, setters

end})
