local Cache = require('./Cache')

local WeakCache = require('class')('WeakCache', Cache)

function WeakCache:__init(constructor, parent)
	Cache.__init(self, constructor, parent)
	setmetatable(self._objects, {__mode = 'v'})
end

-- NOTE: _count is not accurate for weak caches

return Cache
