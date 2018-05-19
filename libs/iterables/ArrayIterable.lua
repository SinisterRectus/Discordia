--[=[@c ArrayIterable x Iterable Iterable class that contains objects in a constant, ordered fashion, although
the order may change if the internal array is modified. Some versions may
use a map function to shape the objects before they are accessed.]=]

local wrap, yield = coroutine.wrap, coroutine.yield

local Iterable = require('iterables/Iterable')

local ArrayIterable, get = require('class')('ArrayIterable', Iterable)

function ArrayIterable:__init(array, map)
	self._array = array
	self._map = map
end

function ArrayIterable:__len()
	local array = self._array
	if not array or #array == 0 then
		return 0
	end
	local map = self._map
	if map then -- map can return nil
		return Iterable.__len(self)
	else
		return #array
	end
end

--[=[@p first * Returns the first object in the array]=]
function get.first(self)
	local array = self._array
	if not array or #array == 0 then
		return nil
	end
	local map = self._map
	if map then
		for i = 1, #array, 1 do
			local v = array[i]
			local obj = v and map(v)
			if obj then
				return obj
			end
		end
	else
		return array[1]
	end
end

--[=[@p last * Returns the last object in the array]=]
function get.last(self)
	local array = self._array
	if not array or #array == 0 then
		return nil
	end
	local map = self._map
	if map then
		for i = #array, 1, -1 do
			local v = array[i]
			local obj = v and map(v)
			if obj then
				return obj
			end
		end
	else
		return array[#array]
	end
end

--[=[
@m iter
@r function
@d Returns an iterator that returns all contained objects in a consistent order.
]=]
function ArrayIterable:iter()
	local array = self._array
	if not array or #array == 0 then
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
