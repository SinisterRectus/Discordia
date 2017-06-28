local wrap, yield = coroutine.wrap, coroutine.yield

local Iterable = require('class')('Iterable')

--[[ NOTE:
- this is more of a mixin, without an initializer
- init and iter methods must be defined in each sub-class
- len and get can be redefined in any sub-class
]]

function Iterable:__len()
	local n = 0
	for _ in self:iter() do
		n = n + 1
	end
	return n
end

function Iterable:get(k) -- objects must be hashable
	for obj in self:iter() do
		if obj:__hash() == k then
			return obj
		end
	end
	return nil
end

function Iterable:find(predicate)
	for obj in self:iter() do
		if predicate(obj) then
			return obj
		end
	end
	return nil
end

function Iterable:findAll(predicate)
	return wrap(function()
		for obj in self:iter() do
			if predicate(obj) then
				yield(obj)
			end
		end
	end)
end

function Iterable:forEach(fn)
	for obj in self:iter() do
		fn(obj)
	end
end

return Iterable
