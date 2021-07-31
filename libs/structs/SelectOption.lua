local class = require('../class')

local PartialEmoji = require('./PartialEmoji')
local Struct = require('./Struct')

local SelectOption, get = class('SelectOption', Struct)

function SelectOption:__init(data)
	Struct.__init(self, data)
	self._emoji = data.emoji and PartialEmoji(data.emoji)
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
