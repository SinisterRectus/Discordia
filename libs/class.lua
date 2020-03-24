local checkCalls = true

local meta = {}
local names = {}
local classes = {}
local members = {}
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

local function isInit(class, fn)
	if not isClass(class) then return false end
	if class.__methods.__init == fn then return true end
	return isInit(class.__base, fn)
end

local function isMember(class, fn)
	if not isClass(class) then return false end
	if members[fn] == class then return true end
	return isMember(class.__base, fn)
end

local function checkInit(class, level)
	local info = debug.getinfo(level, 'f')
	if not isInit(class, info.func) then
		error('cannot declare class property outside of __init', level)
	end
end

local function checkMember(class, level)
	local info = debug.getinfo(level, 'f')
	if not isMember(class, info.func) then
		error('cannot access private class property', level)
	end
end

local function proxy(class, base)
	local tbl = base and setmetatable({}, {__index = base}) or {}
	return setmetatable({}, {
		__index = tbl,
		__newindex = function(self, k, v)
			if type(v) ~= 'function' or members[v] then
				return error('class member must be a unique function')
			end
			members[v] = class
			if k:sub(1, 2) == '__' then
				return rawset(self, k, v)
			end
			if tbl[k] then
				return error('class member already defined')
			end
			tbl[k] = function(obj, ...)
				if not isInstance(obj, class) then
					return error('invalid self; check method:syntax()')
				end
				return v(obj, ...)
			end
		end,
	})
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

	local methods = proxy(class, base and base.__methods)
	local getters = proxy(class, base and base.__getters)
	local setters = proxy(class, base and base.__setters)

	class.__name = name
	class.__base = base or {}
	class.__class = class
	class.__methods = methods
	class.__getters = getters
	class.__setters = setters

	local properties = {}
	local n = 0

	function methods:__index(k)
		local getter = getters[k]
		if getter then
			return getter(self)
		elseif properties[k] then
			if checkCalls then checkMember(class, 3) end
			return rawget(self, properties[k])
		else
			local parent = class[k]
			if parent ~= nil then
				return parent
			end
			return error('undefined class member')
		end
	end

	function methods:__newindex(k, v)
		local setter = setters[k]
		if setter then
			return setter(self, v)
		elseif class[k] or getters[k] then
			return error('cannot override class member')
		elseif k:sub(1, 1) ~= '_' then
			return error('leading underscore required')
		else
			if checkCalls then checkMember(class, 3) end
			if not properties[k] then
				if checkCalls then checkInit(class, 3) end
				n = n + 1
				properties[k] = n
			end
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

	return class, methods, getters, setters

end})
