local colorize = require('pretty-print').colorize

local Error = class('Error')

function Error:__init(message, traceback)
	self.message = message
	self.traceback = traceback
	print(self)
	os.exit()
end

function Error:__tostring()
	return colorize('failure', self.message .. '\n' .. self.traceback)
end

return Error
