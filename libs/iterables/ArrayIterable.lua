local wrap, yield = coroutine.wrap, coroutine.yield

local Iterable = require('iterables/Iterable')

local ArrayIterable = require('class')('ArrayIterable', Iterable)

--[[
@class ArrayIterable x Iterable

Iterable class that contains objects in a constant, ordered fashion, although
the order may change if the internal array is modified. Some versions may
use a map function to shape the objects before they are accessed.
]]
function ArrayIterable:__init(array, map)
	self._array = array
	self._map = map
end

function ArrayIterable:__len()
	local array = self._array
	if not array then
		return 0
	end
	local map = self._map
	if map then -- map can return nil
		return Iterable.__len(self)
	else
		return #array
	end
end

--[[
@method iter
@ret function

Returns an iterator that returns all contained objects in a consistent order.
]]
function ArrayIterable:iter()
	local array = self._array
	if not array then
		return function() -- new closure for consistency
			return nil
		end
	end
	local map = self._map
	if map then
		return wrap(function()
			for _, v in ipairs(array) do
				local obj = map(v)
				if obj then
					yield(obj)
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
