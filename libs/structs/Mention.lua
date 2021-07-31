local class = require('../class')
local Struct = require('./Struct')

local Mention, get = class('Mention', Struct)

function Mention:__init(data)
	Struct.__init(self, data)
end

function get:id()
	return self._id
end

function get:type()
	return self._type
end

function get:raw()
	return self._raw
end

function get:animated()
	return self._animated
end

function get:name()
	return self._name
end

function get:timestamp()
	return self._timestamp
end

function get:style()
	return self._style
end

return Mention
