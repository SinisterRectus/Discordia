local InteractionOption = require('./InteractionOption')

local class = require('../class')
local helpers = require('../helpers')

local InteractionData, get = class('InteractionData')

function InteractionData:__init(data)
	self._id = data.id
	self._name = data.name
	self._resolved = nil -- TODO
	self._options = data.options and helpers.structs(InteractionOption, data.options)
	self._custom_id = data.custom_id
	self._component_type = data.component_type
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

function get:resolved()
	return self._resolved
end

function get:options()
	return self._options
end

function get:customId()
	return self._custom_id
end

function get:componentType()
	return self._component_type
end

return InteractionData
