require('./extensions')
_G.class = require('./class')

return {
	Client = require('./client/Client'),
	Cache = require('./utils/Cache'),
	Color = require('./utils/Color'),
	Deque = require('./utils/Deque'),
	Emitter = require('./utils/Emitter'),
	OrderedCache = require('./utils/OrderedCache'),
	Permissions = require('./utils/Permissions'),
	RateLimiter = require('./utils/RateLimiter'),
	Stopwatch = require('./utils/Stopwatch'),
}
