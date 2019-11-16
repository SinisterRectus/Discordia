--[=[
@c TableIterable x Iterable
@mt mem
@d Iterable class that wraps a basic Lua table, where order is not guaranteed.
Some versions may use a map function to shape the objects before they are accessed.
]=]

local Iterable = require('iterables/Iterable')

local TableIterable = require('class')('TableIterable', Iterable)

function TableIterable:__init(tbl, map)
	self._tbl = tbl
	self._map = map
end

--[=[
@m iter
@r function
@d Returns an iterator that returns all contained objects. The order of the objects is not guaranteed.
]=]
function TableIterable:iter()
	local tbl = self._tbl
	if not tbl then
		return function()
			return nil
		end
	end
	local map = self._map
	if map then
		local k, v
		return function()
			while true do
				k, v = next(tbl, k)
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
		local k, v
		return function()
			k, v = next(tbl, k)
			return v
		end
	end
end

return TableIterable
