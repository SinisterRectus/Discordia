local max = math.max
local insert, sort = table.insert, table.sort
local lower, upper = string.lower, string.upper
local f, rep = string.format, string.rep
local printf = printf -- luacheck: ignore printf

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

local Base -- defined below

local class = setmetatable({__classes = classes}, {__call = function(_, name, ...)

	if classes[name] then return error(f('Class %q already defined', name)) end

	local class = setmetatable({}, meta)
	local getters, setters = {}, {} -- for property metatables
	local properties, methods, caches = {}, {}, {} -- for documentation

	local bases = {Base, ...}
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
		for k, v in pairs(base.__caches) do
			caches[k] = v
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
	class.__caches = caches
	class.__setters = setters
	class.__getters = getters
	class.__methods = methods
	class.__properties = properties
	class.__description = nil

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
			return error(f('Cannot overwrite protected property: %s.%s', name, k))
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

	local function cache(k, count, get, getAll, find, findAll)

		local k1 = k:gsub('^.', lower)
		local k2 = name:gsub('(.*)(%u)', function(_, str) return lower(str) end)

		property(f('%ss', k1), getAll, nil, 'function', f("Iterator for the %s's cached %ss.", k2, k))
		property(f('%sCount', k1), count, nil, 'number', f("How many %ss are cached for the %s.", k, k2))

		class[f('get%s', k)] =	get
		class[f('find%s', k)] = find
		class[f('find%ss', k)]	= findAll

		caches[k] = true

	end

	classes[name] = class

	return class, property, method, cache

end})

Base = class('Base') -- forward-declared above

function Base:__tostring()
	return 'instance of class: ' .. self.__name
end

local function isSub(self, other)
	for _, base in ipairs(self.__bases) do
		if base == other then return true end
		if isSub(base, other) then return true end
	end
	return false
end

function Base:isInstanceOf(name)
	local other = classes[name]
	if not other then return error(f('Class %q is undefined', name)) end
	if self.__name == other.__name then return true, true end
	return isSub(self, other), false
end

local function padRight(str, len)
	return str .. rep(' ', len - #str)
end

local function sorter(a, b)
	return a[1] < b[1]
end

function Base:help()

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
		for _, v in ipairs(properties) do
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
		for _, v in ipairs(methods) do
			printf('%s  %s', padRight(f('%s(%s)', v[1], v[2]), n), padRight(v[3], m))
		end
		print()
	end

end

return class
