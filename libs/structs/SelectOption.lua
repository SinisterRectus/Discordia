local class = require('../class')

local PartialEmoji = require('./PartialEmoji')

local SelectOption, get = class('SelectOption')

function SelectOption:__init(data)
	self._label = data.label
	self._value = data.value
	self._description = data.description
	self._emoji = data.emoji and PartialEmoji(data.emoji)
	self._default = data.default
end

function get:label()
	return self._label
end

function get:value()
	return self._value
end

function get:description()
	return self._description
end

function get:emoji()
	return self._emoji
end

function get:default()
	return self._default
end

return SelectOption
