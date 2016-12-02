require('./extensions')
_G.class = require('./class')

local VoiceClient = require('./client/VoiceClient')

local function loadOpus(filename)
	return VoiceClient._loadOpus(filename)
end

local function loadSodium(filename)
	return VoiceClient._loadSodium(filename)
end

return {
	Client = require('./client/Client'),
	Buffer = require('./utils/Buffer'),
	Cache = require('./utils/Cache'),
	Color = require('./utils/Color'),
	Deque = require('./utils/Deque'),
	Emitter = require('./utils/Emitter'),
	Mutex = require('./utils/Mutex'),
	OrderedCache = require('./utils/OrderedCache'),
	Permissions = require('./utils/Permissions'),
	Stopwatch = require('./utils/Stopwatch'),
	VoiceClient = VoiceClient,
	loadOpus = loadOpus,
	loadSodium = loadSodium,
}
