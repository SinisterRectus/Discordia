--[=[
@c ArrayIterable x Iterable
@mt mem
@d Iterable class that contains objects in a constant, ordered fashion, although
the order may change if the internal array is modified. Some versions may use a
map function to shape the objects before they are accessed.
]=]

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

--[=[@p first * The first object in the array]=]
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

--[=[@p last * The last object in the array]=]
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
@d Returns an iterator for all contained objects in a consistent order.
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
		local i = 0
		return function()
			while true do
				i = i + 1
				local v = array[i]
				if not v then
					return nil
				end
				v = map(v)
				if v then
					return v
				end
			end
		end
	else
		local i = 0
		return function()
			i = i + 1
			return array[i]
		end
	end
end

return ArrayIterable
