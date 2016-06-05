local colorize = require('pretty-print').colorize

local Error = class('Error')

function Error:__init(message, traceback)
	self.message = message
	self.traceback = traceback
	print(self)
end

function Error:__tostring()
	local msg = string.format('%s\n%s\n%s', os.date(), self.message, self.traceback)
	return colorize('failure', msg)
end

return Error
