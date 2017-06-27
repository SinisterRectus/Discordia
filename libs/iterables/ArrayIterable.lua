local Iterable = require('iterables/Iterable')

local ArrayIterable = require('class')('ArrayIterable', Iterable)

function ArrayIterable:__init(array, map)
	self._array = array
	self._map = map
end

function ArrayIterable:__len()
	return self._array and #self._array or 0
end

function ArrayIterable:iter()
	local array = self._array
	if not array then
		return function() end
	end
	local map = self._map
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
