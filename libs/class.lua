local format = string.format

local meta = {}
local classes = {}

-- TODO: instanceof, typeof, subclassof
-- TODO: isObject, isClass

function meta:__call(...)
	local obj = setmetatable({}, self)
	obj:__init(...)
	return obj
end

function meta:__tostring()
	return 'class ' .. self.__name
end

local default = {}

function default:__tostring()
	return 'instance of class ' .. self.__name
end

-- TODO: method to serialize objs

return setmetatable({__classes = classes}, {__call = function(_, name, ...)

	if classes[name] then return error(format('Class %q already defined', name)) end

	local class = setmetatable({__type = 'class'}, meta)

	for k, v in pairs(default) do
		class[k] = v
	end

	local bases = {...}
	local getters, setters = {}, {}

	-- TODO: decide whether we want dynamic get/set methods
	-- local getters = setmetatable({}, {
	-- 	__newindex = function(self, k, fn)
	-- 		class['get' .. k:gsub('^%l', string.upper)] = fn
	-- 		return rawset(self, k, fn)
	-- 	end
	-- })
	--
	-- local setters = setmetatable({}, {
	-- 	__newindex = function(self, k, fn)
	-- 		class['set' .. k:gsub('^%l', string.upper)] = fn
	-- 		return rawset(self, k, fn)
	-- 	end
	-- })

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

	-- TODO: property pool
	-- TODO: maybe remove setters

	function class:__index(k)
		local getter = getters[k]
		if getter then
			return getter(self)
		else
			return class[k]
		end
	end

	function class:__newindex(k, v)
		assert(k:find('_') == 1) -- debug
		local setter = setters[k]
		if setter then
			return setter(self, v)
		elseif class[k] or getters[k] then
			return error(format('Cannot overwrite protected property: %s.%s', name, k))
		else
			return rawset(self, k, v)
		end
	end

	classes[name] = class

	return class, getters

end})
