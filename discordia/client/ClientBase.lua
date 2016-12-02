local pp = require('pretty-print')

local Emitter = require('../utils/Emitter')

local format = string.format
local colorize = pp.colorize
local traceback = debug.traceback
local date, exit = os.date, os.exit
local running = coroutine.running

local ClientBase = class('ClientBase', Emitter)

function ClientBase:__init(customOptions, defaultOptions)
	Emitter.__init(self)
	if customOptions then
		local options = {}
		for k, v in pairs(defaultOptions) do
			if customOptions[k] ~= nil then
				options[k] = customOptions[k]
			else
				options[k] = v
			end
		end
		self._options = options
	else
		self._options = defaultOptions
	end
end

local function log(self, message, color)
	return print(colorize(color, format('%s - %s', date(self._options.dateTime), message)))
end

function ClientBase:warning(message)
	if self._listeners['warning'] then return self:emit('warning', message) end
	return log(self, message, 'highlight')
end

function ClientBase:error(message)
	if self._listeners['error'] then return self:emit('error', message) end
	log(self, traceback(running(), message, 2), 'failure')
	return exit()
end

return ClientBase
