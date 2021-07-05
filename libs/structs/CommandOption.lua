local CommandChoice = require('./CommandChoice')

local class = require('../class')
local helpers = require('../helpers')

local CommandOption, get = class('CommandOption')

function CommandOption:__init(data)
	self._type = data.type
	self._name = data.name
	self._description = data.description
	self._required = data.required
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
