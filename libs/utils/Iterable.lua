local Iterable = require('class')('Iterable')

--[[ NOTE:
- this is more of a mixin, without an initializer
- default length method can be redefined in sub-classes
- iter method must be defined in sub-classes
]]

function Iterable:__len()
	local n = 0
	for _ in self:iter() do
		n = n + 1
	end
	return n
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
	return coroutine.wrap(function()
		for obj in self:iter() do
			if predicate(obj) then
				coroutine.yield(obj)
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
