class('Error')

function Error:__init(message, traceback)
    self.message = message
    self.traceback = traceback
end

function Error:__tostring()
    return string.format('%s\n%s', self.message, self.traceback)
end

function Error:raise()
    error(tostring(self))
end

return Error
