local wrap, yield = coroutine.wrap, coroutine.yield

local Iterable = require('iterables/Iterable')

local ArrayIterable = require('class')('ArrayIterable', Iterable)

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

function ArrayIterable:__json(null)
	local objects = {}
	if self._map then
		return wrap(function()
			for _, v in ipairs(self._array) do
				local obj = map(v)
				if obj then
					table.insert(objects, obj:__json())
				end
			end
		end)
	else
		for i = 0, #self._array do
			objects[i] = self._array[i]
		end
	end
	
	return {
		type = 'ArrayIterable',

		array = objects
	}
end

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
