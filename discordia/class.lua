local memoryOptimization = _OPTIONS.memoryOptimization

local meta = {}

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

return function(name, ...)

	local class = setmetatable({}, meta)
	local accessors = {}

	for k, v in pairs(default) do
		class[k] = v
	end

	local bases = {...}
	for _, base in ipairs(bases) do
		for k, v in pairs(base) do
			class[k] = v
		end
		for k, v in pairs(base.__accessors) do
			accessors[k] = v
		end
	end

	class.__name = name
	class.__bases = bases
	class.__class = class
	class.__accessors = accessors

	if memoryOptimization then

		local properties = {}

		function class:__index(k)
			local accessor = accessors[k]
			if accessor then
				return accessor(self)
			else
				local i = properties[k]
				if i then
					return rawget(self, i)
				end
				return class[k]
			end
		end

		function class:__newindex(k, v)
			local i = properties[k]
			if not i then
				i = #self + 1
				properties[k] = i
			end
			rawset(self, i, v)
		end

	else

		function class:__index(k)
			local accessor = accessors[k]
			if accessor then
				return accessor(self)
			else
				return class[k]
			end
		end

	end

	return class, accessors

end
