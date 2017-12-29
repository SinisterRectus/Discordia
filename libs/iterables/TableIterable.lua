local wrap, yield = coroutine.wrap, coroutine.yield

local Iterable = require('iterables/Iterable')

local TableIterable = require('class')('TableIterable', Iterable)

function TableIterable:__init(tbl, map)
	self._tbl = tbl
	self._map = map
end

function TableIterable:__serializeJSON(null)
	local tbl = {}
	for k, v in pairs(self._tbl) do
		if v.__serializeJSON then
			tbl[k] = v:__serializeJSON(null)
		else
			tbl[k] = v
		end
	end

	return {
		type = 'TableIterable',

		table = self._tbl
	}
end

function TableIterable:iter()
	local tbl = self._tbl
	if not tbl then
		return function()
			return nil
		end
	end
	local map = self._map
	if map then
		return wrap(function()
			for _, v in pairs(tbl) do
				local obj = map(v)
				if obj then
					yield(obj)
				end
			end
		end)
	else
		local k, v
		return function()
			k, v = next(tbl, k)
			return v
		end
	end
end

return TableIterable
