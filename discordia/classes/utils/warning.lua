local Warning = class('Warning')

function Warning:__init(message)
	self.message = message
end

function Warning:__tostring()
	return self.message
end

return Warning
