require('./extensions')
_G.class = require('./class')

return {
	Client = require('./client/Client'),
	Cache = require('./utils/Cache'),
	Color = require('./utils/Color'),
	Deque = require('./utils/Deque'),
	Emitter = require('./utils/Emitter'),
	Mutex = require('./utils/Mutex'),
	OrderedCache = require('./utils/OrderedCache'),
	Permissions = require('./utils/Permissions'),
	Stopwatch = require('./utils/Stopwatch'),
}
