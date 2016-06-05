local colorize = require('pretty-print').colorize

local Warning = class('Warning')

function Warning:__init(message, traceback)
	self.message = message
	self.traceback = traceback
	print(self)
end

function Warning:__tostring()
	local msg = string.format('%s\n%s\n%s', os.date(), self.message, self.traceback)
	return colorize('highlight', msg)
end

return Warning
