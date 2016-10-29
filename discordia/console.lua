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

local info = setmetatable({}, {
	__call = function(self, msg)
		return log(msg, 'string')
	end
})

local warning = setmetatable({}, {
	__call = function(self, msg)
		return log(msg, 'highlight')
	end
})

local failure = setmetatable({}, {
	__call = function(self, msg)
		log(traceback(running(), msg, 2), 'failure')
		return exit()
	end
})

function warning.cache(object, event)
	return warning(format('Attempted to access uncached %q on %q', object, event))
end

function warning.deprecated(got, expected)
	return warning(format('%q is deprecated; use %q instead', got, expected))
end

function warning.http(method, url, res, data)
	local message = data.message or 'No additional information'
	return warning(format('%i / %s / %s\n%s %s', res.code, res.reason, message, method, url))
end

function warning.time(provided, calculated)
	return warning(format('Calculated %q from %q', calculated, provided))
end

return {
	info = info,
	warning = warning,
	failure = failure,
}
