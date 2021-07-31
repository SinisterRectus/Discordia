local class = require('../class')

local Struct = require('./Struct')

local CommandChoice, get = class('CommandChoice', Struct)

function CommandChoice:__init(data)
	Struct.__init(self, data)
end

function get:name()
	return self._name
end

function get:value()
	return self._value
end

return CommandChoice
