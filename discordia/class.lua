local mt = {}

function mt:__call(...)
	local obj = setmetatable({}, self)
	if type(obj.__init) == 'function' then
		obj:__init(...)
	end
	return obj
end

function mt:__tostring()
	return 'class: ' .. self.__name
end

local function obj__tostring(self)
	return 'instance of class: ' .. self.__name
end

return function(name, ...)

	assert(type(name) == 'string', 'Invalid class name')

	local class = setmetatable({__tostring = obj__tostring}, mt)

	local bases = {...}
	for _, base in ipairs(bases)  do
		for k, v in next, base do
			rawset(class, k, v)
		end
	end

	rawset(class, '__name', name)
	rawset(class, '__index', class)
	rawset(class, '__bases', bases)

	return class

end
