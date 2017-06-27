local Cache = require('./Cache')

local WeakCache = require('class')('WeakCache', Cache)

function WeakCache:__init(constructor, parent)
	Cache.__init(self, constructor, parent)
	setmetatable(self._objects, {__mode = 'v'})
end

-- NOTE: _count is not accurate for weak caches

function WeakCache:__len()
	local n = 0
	for _ in self:iter() do
		n = n + 1
	end
	return n
end

return WeakCache
