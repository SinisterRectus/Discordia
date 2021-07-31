local class = require('../class')
local Struct = require('./Struct')

local EmbedField, get = class('EmbedField', Struct)

function EmbedField:__init(data)
	Struct.__init(self, data)
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
