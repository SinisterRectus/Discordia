local colorize = require('pretty-print').colorize

local function log(msg, color)
	msg = string.format('%s - %s', os.date(), msg)
	msg = colorize(color, msg)
	return print(msg)
end

local console = {}

function console.failure(msg)
	log(debug.traceback(coroutine.running(), msg, 2), 'failure')
	os.exit()
end

function console.success(msg)
	return log(msg, 'success')
end

console.warning = setmetatable({}, {
	__call = function(self, msg)
		return log(msg, 'highlight')
	end
})

function console.warning.cache(object, event)
	return console.warning(string.format('Attempted to access uncached %q on %q', object, event))
end

function console.warning.deprecated(got, expected)
	return console.warning(string.format('%q is deprecated; use %q instead', got, expected))
end

function console.warning.http()
end

return console
