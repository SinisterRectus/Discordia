local colorize = require('pretty-print').colorize

local Error = class('Error')

function Error:__init(message, traceback)
	self.message = message or ''
	self.traceback = traceback or ''
	print(self)
end

function Error:__tostring()
	return colorize('failure', self.message .. '\n' .. self.traceback)
end

return Error
