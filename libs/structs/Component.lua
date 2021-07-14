local class = require('../class')
local helpers = require('../helpers')

local PartialEmoji = require('./PartialEmoji')
local SelectOption = require('./SelectOption')

local Component, get = class('Component')

function Component:__init(data)
	self._type = data.type -- all
	self._style = data.style -- button
	self._label = data.label -- button
	self._emoji = data.emoji and PartialEmoji(data) -- button
	self._custom_id = data.custom_id -- button, select menu
	self._url = data.url -- button
	self._disabled = data.disabled -- button, select menu
	self._components = helpers.structs(data.components, Component) -- action row
	self._options = helpers.structs(data.options, SelectOption) -- select menu
	self._placeholder = data.placeholder
	self._min_values = data.min_values
	self._max_values = data.max_values
end

function get:type()
	return self._type
end

function get:style()
	return self._style
end

function get:label()
	return self._label
end

function get:emoji()
	return self._emoji
end

function get:customId()
	return self._custom_id
end

function get:url()
	return self._url
end

function get:disabled()
	return self._disabled
end

function get:components()
	return self._components
end

function get:options()
	return self._options
end

function get:placeholder()
	return self._placeholder
end

function get:minValues()
	return self._min_values
end

function get:maxValues()
	return self._max_values
end

return Component
