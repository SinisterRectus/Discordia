local colorize = require('pretty-print').colorize

local format = string.format
local running = coroutine.running
local traceback = debug.traceback
local date, exit = os.date, os.exit

local function log(msg, color)
	msg = format('%s - %s', date(), msg)
	msg = colorize(color, msg)
	return print(msg)
end

local console = {}

console.success = setmetatable({}, {
	__call = function(self, msg)
		return log(msg, 'success')
	end
})

console.warning = setmetatable({}, {
	__call = function(self, msg)
		return log(msg, 'highlight')
	end
})

console.failure = setmetatable({}, {
	__call = function(self, msg)
		log(traceback(running(), msg, 2), 'failure')
		return exit()
	end
})

function console.warning.cache(object, event)
	return console.warning(format('Attempted to access uncached %q on %q', object, event))
end

function console.warning.deprecated(got, expected)
	return console.warning(format('%q is deprecated; use %q instead', got, expected))
end

function console.warning.http()
end

return console
