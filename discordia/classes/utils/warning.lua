local colorize = require('pretty-print').colorize

local Warning = class('Warning')

function Warning:__init(message, traceback)
	self.message = message
	self.traceback = traceback
	print(self)
end

function Warning:__tostring()
	return colorize('highlight', self.message .. '\n' .. self.traceback)
end

return Warning
