local create, resume, yield = coroutine.create, coroutine.resume, coroutine.yield

return function(name, ...)

	assert(type(name) == 'string', 'Invalid class name')

	local class = {}
	local properties = {}

	local objMeta = {
		__index = function(self, k)
			if properties[k] then
				return rawget(self, properties[k])
			else
				return class[k]
			end
		end,
		__newindex = function(self, k, v)
			if properties[k] then
				rawset(self, properties[k], v)
			else
				local i = #self + 1
				properties[k] = i
				rawset(self, i, v)
			end
		end,
		__pairs = function(self)
			local coro = create(function()
				for k, i in pairs(properties) do
					yield(k, rawget(self, i))
				end
			end)
			return function()
				local success, k, v = resume(coro)
				return k, v
			end
		end,
	}

	setmetatable(class, {
		__call = function(self, ...)
			for k, v in pairs(self) do
				objMeta[k] = objMeta[k] or v
			end
			local obj = setmetatable({}, objMeta)
			if obj.__init then obj:__init(...) end
			return obj
		end,
		__tostring = function(self)
			return "Class: " .. name
		end
	})

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
