local max = math.max
local insert, sort = table.insert, table.sort
local format, upper, rep = string.format, string.upper, string.rep

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

local Object -- defined below

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
			methods[k] = v
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
			return class[k]
		end
	end

	function class:__newindex(k, v)
		local setter = setters[k]
		if setter then
			return setter(self, v)
		elseif class[k] or properties[k] then
			return error(format('Cannot overwrite protected property: %s.%s', name, k))
		else
			return rawset(self, k, v)
		end
	end

	local function property(k, get, set, t, d)

		assert(type(k) == 'string')
		assert(type(t) == 'string')
		assert(type(d) == 'string' and #d < 120)

		local m = k:gsub('^%l', upper)

		local getter = get
		if type(get) == 'string' then
			getter = function(self) return self[get] end
		end
		assert(type(getter) == 'function')
		getters[k] = getter
		class['get' .. m] = getter

		if set then
			local setter = set
			if type(set) == 'string' then
				setter = function(self, v) self[set] = v end
			end
			assert(type(setter) == 'function')
			setters[k] = setter
			class['set' .. m] = setter
		end

		properties[k] = {t, d}

	end

	local function method(k, fn, params, desc)
		assert(type(k) == 'string')
		assert(type(fn) == 'function')
		assert(type(desc) == 'string' and #desc < 120)
		class[k] = fn
		methods[k] = {params or '', desc}
	end

	classes[name] = class

	return class, property, method

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

local function padRight(str, len)
	return str .. rep(' ', len - #str)
end

local function sorter(a, b)
	return a[1] < b[1]
end

function Object:help()

	printf('\n-- %s --\n%s\n', self.__name, self.__description)

	if next(self.__properties) then
		local properties = {}
		local n, m = 0, 0
		for k, v in pairs(self.__properties) do
			insert(properties, {k, v[1], v[2]})
			n = max(n, #k)
			m = max(m, #v[1])
		end
		sort(properties, sorter)
		for i, v in ipairs(properties) do
			printf('%s  %s  %s', padRight(v[1], n), padRight(v[2], m), v[3])
		end
		print()
	end

	if next(self.__methods) then
		local methods = {}
		local n, m = 0, 0
		for k, v in pairs(self.__methods) do
			insert(methods, {k, v[1], v[2]})
			n = max(n, #k + #v[1] + 2)
			m = max(m, #v[2])
		end
		sort(methods, sorter)
		for i, v in ipairs(methods) do
			printf('%s  %s', padRight(format('%s(%s)', v[1], v[2]), n), padRight(v[3], m))
		end
		print()
	end

end

return class
