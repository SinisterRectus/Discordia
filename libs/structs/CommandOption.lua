local CommandChoice = require('./CommandChoice')

local Struct = require('./Struct')

local class = require('../class')
local helpers = require('../helpers')

local CommandOption, get = class('CommandOption', Struct)

function CommandOption:__init(data)
	Struct.__init(self, data)
	self._choices = data.choices and helpers.structs(CommandChoice, data.choices)
	self._options = data.options and helpers.structs(CommandOption, data.options)
end

function get:type()
	return self._type
end

function get:name()
	return self._name
end

function get:description()
	return self._description
end

function get:required()
	return self._required or false
end

function get:choices()
	return self._choices
end

function get:options()
	return self._options
end

return CommandOption
