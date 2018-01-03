local Cache = require('iterables/Cache')
local Iterable = require('iterables/Iterable')

local WeakCache = require('class')('WeakCache', Cache)

function WeakCache:__init(array, constructor, parent)
	Cache.__init(self, array, constructor, parent)
	setmetatable(self._objects, {__mode = 'v'})
end

function WeakCache:__serializeJSON(null)
	local objects = {}
	for hash, obj in pairs(self._objects) do
		objects[hash] = obj:__serializeJSON()
	end

	return {
		type = 'WeakCache',

		objects = objects
	}
end

function WeakCache:__len() -- NOTE: _count is not accurate for weak caches
	return Iterable.__len(self)
end

return WeakCache
