return function(...)

	local class, bases, name = {}, {...}

	if type(bases[1]) == 'string' then
		name = table.remove(bases, 1)
		getfenv(2)[name] = class
	end

	for _, base in ipairs(bases)  do
		for k, v in pairs(base) do
			class[k] = v
		end
	end

	class.__name = name
	class.__index = class
	class.__bases = bases

	setmetatable(class, {
		__call = function(class, ...)
			local obj = setmetatable({}, class)
			if type(obj.__init) == 'function' then
				obj:__init(...)
			end
			return obj
		end
	})

	return class

end
