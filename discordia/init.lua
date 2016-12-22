require('./extensions')
_G.class = require('./class')

return {
	Client = require('./client/Client'),
	Buffer = require('./utils/Buffer'),
	Cache = require('./utils/Cache'),
	Clock = require('./utils/Clock'),
	Color = require('./utils/Color'),
	Deque = require('./utils/Deque'),
	Emitter = require('./utils/Emitter'),
	Mutex = require('./utils/Mutex'),
	OrderedCache = require('./utils/OrderedCache'),
	Permissions = require('./utils/Permissions'),
	Stopwatch = require('./utils/Stopwatch'),
	package = require('./package')
}
