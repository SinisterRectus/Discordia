local insert = table.insert
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

-- local docs = {classes = {}}
--
-- setmetatable(docs, {__call = function(self, name, desc)
--
-- 	local class = {name, desc, properties = {}, methods = {}}
--
-- 	function class.property(name, type, mutable, desc)
-- 		insert(class.properties, {name, type, mutable, desc})
-- 		return class
-- 	end
--
-- 	function class.method(name, desc)
-- 		insert(class.methods, {name, desc, args = {}, rets = {}})
-- 		return class
-- 	end
--
-- 	function class.arg(name, type, desc)
-- 		local methods = class.methods
-- 		insert(methods[#methods].args, {name, type, desc})
-- 		return class
-- 	end
--
-- 	function class.ret(type)
-- 		local methods = class.methods
-- 		insert(methods[#methods].rets, type)
-- 		return class
-- 	end
--
-- 	function class.dump() -- debug
-- 		p(class[1], class[2])
-- 		for _, property in ipairs(class.properties) do
-- 			p('', property)
-- 		end
-- 		for _, method in ipairs(class.methods) do
-- 			p('', method[1], method[2])
-- 			for _, arg in ipairs(method.args) do
-- 				p('', '', arg)
-- 			end
-- 			for _, ret in ipairs(method.rets) do
-- 				p('', '', ret)
-- 			end
-- 		end
-- 	end
--
-- 	insert(docs.classes, class)
-- 	return class
--
-- end})

local Object -- define below

local class = setmetatable({__classes = classes, docs = docs}, {__call = function(self, name, ...)

	if classes[name] then return error(format('Class %q already defined', name)) end

	local class = setmetatable({}, meta)
	local properties, methods = {}, {} -- for documentation
	local getters, setters = {}, {} -- for property metatables

	local bases = {Object, ...}
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
		for k, v in pairs(base.__methods) do
			properties[k] = v
		end
		for k, v in pairs(base.__properties) do
			properties[k] = v
		end
	end

	class.__name = name
	class.__bases = bases
	class.__setters = setters
	class.__getters = getters
	class.__methods = methods
	class.__properties = properties

	function class:__index(k)
		local getter = getters[k]
		if getter then
			return getter(self)
		else
			return methods[k] or class[k]
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

	local function property(k, get, set, t, d)

		assert(k and t and d)
		local m = k:gsub('^%l', upper)

		local getter = get
		if type(get) == 'string' then
			getter = function(class) return class[get] end
		end
		assert(type(getter) == 'function')
		getters[k] = getter
		class['get' .. m] = getter

		if set then
			local setter = set
			if type(set) == 'string' then
				setter = function(class, v) class[set] = v end
			end
			assert(type(setter) == 'function')
			setters[k] = setter
			class['set' .. m] = setter
		end

		properties[k] = {t, d}

	end

	classes[name] = class

	return class, property

end})

Object = class('Object') -- forward-declared above

function Object:__tostring()
	return 'instance of class: ' .. self.__name
end

local function isSub(class, base)
	for _, other in ipairs(class.__bases) do
		if other == base then return true end
		if isSub(other, base) then return true end
	end
	return false
end

function Object:isInstanceOf(name)
	local class = classes[name]
	if not class then return error(format('Class %q is undefined', name)) end
	if self.__name == class then return true, true end
	return isSub(self.__name, class), false
end

function Object:help()
	for k, v in pairs(self.__properties) do
		p(k, v)
	end
end

return class
