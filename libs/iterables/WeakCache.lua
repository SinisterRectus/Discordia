--[=[
@c WeakCache x Cache
@mt mem
@d Extends the functionality of a regular cache by making use of weak references
to the objects that are cached. If all references to an object are weak, as they
are here, then the object will be deleted on the next garbage collection cycle.
]=]

local Cache = require('iterables/Cache')
local Iterable = require('iterables/Iterable')

local WeakCache = require('class')('WeakCache', Cache)

function WeakCache:__init(array, constructor, parent)
	Cache.__init(self, array, constructor, parent)
	setmetatable(self._objects, {__mode = 'v'})
end

function WeakCache:__len() -- NOTE: _count is not accurate for weak caches
	return Iterable.__len(self)
end

return WeakCache
