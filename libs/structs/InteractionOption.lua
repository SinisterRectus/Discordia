local class = require('../class')
local helpers = require('../helpers')
local Struct = require('./Struct')

local InteractionOption, get = class('InteractionOption', Struct)

function InteractionOption:__init(data)
	Struct.__init(self, data)
	self._options = data.options and helpers.structs(InteractionOption, data.options)
end

function get:name()
	return self._name
end

function get:type()
	return self._type
end

function get:value()
	return self._value
end

function get:options()
	return self._options
end

return InteractionOption
