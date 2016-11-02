local format, upper = string.format, string.upper

local meta = {}
local classes = {}

function meta:__call(...)
	local obj = setmetatable({}, self)
	obj:__init(...)
	return obj
end

function meta:__tostring()
	return 'class: ' .. self.__name
end

local default = {}

function default:__tostring()
	return 'instance of class: ' .. self.__name
end

local function isSub(class, base)
	for _, other in ipairs(class.__bases) do
		if other == base then return true end
		if isSub(other, base) then return true end
	end
	return false
end

-- function default:isInstanceOf(class)
-- 	class = type(class) == 'string' and classes[class] or class
-- 	if type(class) ~= 'table' then return error(format('%q is not a class', class)) end
-- 	if self.__class == class then return true, true end
-- 	return isSub(self.__class, class), false
-- end

local function constructor(self, name, ...)

	if classes[name] then return error(format('Class %q already defined', name)) end

	local class = setmetatable({}, meta)
	local properties = {}
	local getters, setters = {}, {}

	for k, v in pairs(default) do
		class[k] = v
	end

	local bases = {...}
	for _, base in ipairs(bases) do
		for k, v in pairs(base) do
			class[k] = v
		end
		for k, v in pairs(base.__getters) do
			getters[k] = v
		end
		for k, v in pairs(base.__setters) do
			setters[k] = v
		end
		for k, v in pairs(base.__properties) do
			properties[k] = v
		end
	end

	class.__name = name
	class.__bases = bases
	class.__class = class
	class.__setters = setters
	class.__getters = getters
	class.__properties = properties

	function class:__index(k)
		local getter = getters[k]
		if getter then
			return getter(self)
		else
			return class[k]
		end
	end

	function class:__newindex(k, v)
		local setter = setters[k]
		if setter then
			return setter(self, v)
		elseif class[k]  or properties[k] then
			return error(format('Cannot overwrite protected property: %s.%s', name, k))
		else
			return rawset(self, k, v)
		end
	end

	local function get(k, callback, typeStr)
		assert(typeStr) -- only used for docs
		if type(callback) == 'string' then
			local property = callback
			callback = function(class) return class[property] end
		end
		getters[k] = callback
		class['get' .. k:gsub('^%l', upper)] = callback
		properties[k] = typeStr
	end

	local function set(k, callback)
		if type(callback) == 'string' then
			local property = callback
			callback = function(class, v) class[property] = v end
		end
		setters[k] = callback
		class['set' .. k:gsub('^%l', upper)] = callback
		properties[k] = properties[k] or ''
	end

	classes[name] = class

	return class, get, set

end

return setmetatable({__classes = classes}, {__call = constructor})
