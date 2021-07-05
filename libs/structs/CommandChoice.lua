local class = require('../class')

local CommandChoice, get = class('CommandChoice')

function CommandChoice:__init(data)
	self._name = data.name
	self._value = data.value
end

function get:name()
	return self._name
end

function get:value()
	return self._value
end

return CommandChoice
