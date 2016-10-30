_G._OPTIONS = {
	memoryOptimization = false,
}

require('./extensions')
_G.class = require('./class')
_G.console = require('./console')

return {
	Client = require('./client/Client'),
	Cache = require('./utils/Cache'),
	Color = require('./utils/Color'),
	Container = require('./utils/Container'),
	Deque = require('./utils/Deque'),
	OrderedCache = require('./utils/OrderedCache'),
	Permissions = require('./utils/Permissions'),
	RateLimiter = require('./utils/RateLimiter'),
	Stopwatch = require('./utils/Stopwatch'),
}
