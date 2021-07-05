local class = require('../class')
local helpers = require('../helpers')

local InteractionOption, get = class('InteractionOption')

function InteractionOption:__init(data)
	self._name = data.name
	self._type = data.type
	self._value = data.value
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
