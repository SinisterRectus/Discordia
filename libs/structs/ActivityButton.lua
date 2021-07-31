local class = require('../class')

local Struct = require('./Struct')

local ActivityButton, get = class('ActivityButton', Struct)

function ActivityButton:__init(data)
	Struct.__init(self, data)
end

function get:label()
	return self._label
end

function get:url()
	return self._url
end

return ActivityButton
