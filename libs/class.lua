local names = {}
local classes = {}
local objects = setmetatable({}, {__mode = 'k'})

local function isClass(cls)
	return classes[cls]
end

local function isObject(obj)
	return objects[obj]
end

local function isSubclass(sub, cls)
	if isClass(sub) and isClass(cls) then
		return sub == cls or isSubclass(getmetatable(sub).__index, cls)
	end
	return false
end

local function isInstance(obj, cls)
	return isObject(obj) and isSubclass(getmetatable(obj), cls)
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

local function copy(obj)
	assert(isObject(obj))
	local new = setmetatable({}, getmetatable(obj))
	objects[new] = true
	for k, v in next, obj do
		rawset(new, k, v)
	end
	return new
end

return setmetatable({

	isClass = isClass,
	isObject = isObject,
	isSubclass = isSubclass,
	isInstance = isInstance,
	profile = profile,
	copy = copy,

}, {__call = function(_, name, base)

	assert(type(name) == 'string', 'name must be a string')
	assert(not names[name], 'class already defined: ' .. name)
	assert(base == nil or isClass(base), 'base must be a class')

	names[name] = true

	local meta = {__index = base}

	function meta:__call(...)
		local obj = setmetatable({}, self)
		objects[obj] = true
		obj:__init(...)
		return obj
	end

	function meta:__tostring()
		return 'class: ' .. self.__name
	end

	local class = setmetatable({__name = name}, meta)
	classes[class] = true

	local get = {}
	local set = {}

	if base then
		setmetatable(get, {__index = base.__getter})
		setmetatable(set, {__index = base.__setter})
	end

	class.__getter = get
	class.__setter = set

	function class:__index(k)
		if get[k] then
			return get[k](self)
		elseif class[k] ~= nil then
			return class[k]
		elseif k:sub(1, 1) == '_' then
			return rawget(self, k)
		else
			return error('undefined class member: ' .. tostring(k))
		end
	end

	function class:__newindex(k, v)
		if set[k] then
			return set[k](self, v)
		elseif class[k] or get[k] then
			return error('cannot override class member: ' .. tostring(k))
		elseif k:sub(1, 1) == '_' then
			return rawset(self, k, v)
		else
			return error('undefined class member: ' .. tostring(k))
		end
	end

	local prefix = name .. ': '
	function class:__tostring()
		if class.toString then
			return prefix .. class.toString(self)
		else
			return 'object: ' .. name
		end
	end

	-- function class:__pairs()
	-- 	local k, fn
	-- 	return function()
	-- 		k, fn = next(get, k)
	-- 		if k then
	-- 			return k, fn(self)
	-- 		end
	-- 	end
	-- end

	return class, get, set

end})
