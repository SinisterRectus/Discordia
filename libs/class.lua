local insert, sort = table.insert, table.sort

local checkCalls = true

local meta = {}
local names = {}
local bases = {}
local getters = {}
local setters = {}
local classes = {}
local objects = setmetatable({}, {__mode = 'k'})

function meta:__call(...)
	local obj = setmetatable({}, self)
	objects[obj] = true
	obj:__init(...)
	return obj
end

function meta:__tostring()
	return 'class: ' .. names[self]
end

local function isClass(cls)
	return classes[cls]
end

local function isObject(obj)
	return objects[obj]
end

local function isSubclass(sub, cls)
	if isClass(sub) and isClass(cls) then
		return sub == cls or isSubclass(bases[sub], cls)
	end
	return false
end

local function isInstance(obj, cls)
	return isObject(obj) and isSubclass(getmetatable(obj), cls)
end

local function profile()
	local counts = {}
	for cls in pairs(classes) do
		counts[names[cls]] = 0
	end
	for obj in pairs(objects) do
		local name = names[getmetatable(obj)]
		counts[name] = counts[name] + 1
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
	if class.__init == fn then return true end
	return isInit(bases[class], fn)
end

local function has(tbl, value)
	for _, v in pairs(tbl) do
		if v == value then return true end
	end
end

local function isMember(class, fn)
	if not isClass(class) then return false end
	if has(class, fn) then return true end
	if has(getters[class], fn) then return true end
	if has(setters[class], fn) then return true end
	return isMember(bases[class], fn)
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

local function copy(obj)
	assert(isObject(obj))
	local new = {}
	for k, v in next, obj do
		new[k] = v
	end
	objects[new] = true
	return setmetatable(new, getmetatable(obj))
end

local function info(class)

	if isObject(class) then
		class = getmetatable(class)
	elseif not isClass(class) then
		return error('must be a class or object')
	end

	local ret = {
		name = names[class],
		base = bases[class] and names[bases[class]],
		class = {},
		getters = {},
		setters = {},
	}

	for k in pairs(class) do insert(ret.class, k); sort(ret.class) end
	for k in pairs(getters[class]) do insert(ret.getters, k); sort(ret.getters) end
	for k in pairs(setters[class]) do insert(ret.setters, k); sort(ret.setters) end

	return ret

end

return setmetatable({

	isClass = isClass,
	isObject = isObject,
	isSubclass = isSubclass,
	isInstance = isInstance,
	profile = profile,
	mixin = mixin,
	copy = copy,
	info = info,

}, {__call = function(_, name, base)

	assert(type(name) == 'string', 'name must be a string')
	assert(base == nil or isClass(base), 'base must be a class')
	assert(not has(names, name), 'class already defined: ' .. name)

	local class = setmetatable({}, meta)
	classes[class] = true

	local get = {}
	local set = {}

	if base then
		mixin(class, base)
		mixin(get, getters[base])
		mixin(set, setters[base])
	end

	local properties = {}
	local n = 0

	names[class] = name
	bases[class] = base
	getters[class] = get
	setters[class] = set

	function class:__index(k)
		if get[k] then
			return get[k](self)
		elseif properties[k] then
			if checkCalls and k:sub(1, 1) == '_' then checkMember(class, 3) end
			return rawget(self, properties[k])
		elseif class[k] ~= nil then
			return class[k]
		else
			return error('undefined class member: ' .. tostring(k))
		end
	end

	function class:__newindex(k, v)
		if set[k] then
			return set[k](self, v)
		elseif class[k] or get[k] then
			return error('cannot override class member: ' .. tostring(k))
		else
			if checkCalls and k:sub(1, 1) == '_' then checkMember(class, 3) end
			if not properties[k] then
				if checkCalls then checkInit(class, 3) end
				n = n + 1
				properties[k] = n
			end
			return rawset(self, properties[k], v)
		end
	end

	function class:__tostring()
		local fn = class.toString
		if fn then
			return name .. ': ' .. fn(self)
		else
			return 'object: ' .. name
		end
	end

	function class:__pairs()
		local k, fn
		return function()
			k, fn = next(get, k)
			if k then
				return k, fn(self)
			end
		end
	end

	return class, get, set

end})
