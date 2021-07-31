local class = require('../class')
local Struct = require('./Struct')

local PartialEmoji, get = class('PartialEmoji', Struct)

function PartialEmoji:__init(data)
	Struct.__init(self, data)
end

function get:name()
	return self._name
end

function get:id()
	return self._id
end

function get:hash()
	if self._id then
		return self._name .. ':' .. self._id
	else
		return self._name
	end
end

function get:animated()
	return self._animated
end

return PartialEmoji
