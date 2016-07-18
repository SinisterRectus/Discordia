require('./extensions')
_G.class = require('./class')

local console = require('./console')

_G.success = console.success
_G.warning = console.warning
_G.failure = console.failure

_G.pt = function(tbl) -- debug
	for k, v in pairs(tbl) do
		print(k, v)
	end
end

_G.ptt = function(tbl) -- debug
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			print(k, v)
		end
	end
end

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
