local Iterable = require('iterables/Iterable')

local ArrayIterable = require('class')('ArrayIterable', Iterable)

function ArrayIterable:__init(array, map)
	self._array = array or {}
	self._map = map
end

function ArrayIterable:__len()
	return #self._array
end

function ArrayIterable:iter()
	local map = self._map
	local array = self._array
	if map then
		return coroutine.wrap(function()
			for _, v in ipairs(array) do
				local obj = map(v)
				if obj then
					coroutine.yield(obj)
				end
			end
		end)
	else
		local i = 0
		return function()
			i = i + 1
			return array[i]
		end
	end
end

return ArrayIterable
