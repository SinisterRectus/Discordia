local InteractionOption = require('./InteractionOption')
local Struct = require('./Struct')

local class = require('../class')
local helpers = require('../helpers')

local InteractionData, get = class('InteractionData', Struct)

function InteractionData:__init(data)
	Struct.__init(self, data)
	self._options = data.options and helpers.structs(InteractionOption, data.options)
	-- TODO: resolved
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
