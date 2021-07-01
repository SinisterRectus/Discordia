local class = require('../class')

local EmbedField, get = class('EmbedField')

function EmbedField:__init(data)
	self._name = data.name
	self._value = data.value
	self._inline = data.inline
end

function get:name()
	return self._name
end

function get:value()
	return self._value
end

function get:inline()
	return self._inline
end

return EmbedField
