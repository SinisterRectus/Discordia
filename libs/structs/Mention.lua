local class = require('../class')

local Mention, get = class('Mention')

function Mention:__init(data)
	self._id = data.id
	self._type = data.type
	self._raw = data.raw
	self._animated = data.animated
	self._name = data.name
	self._timestamp = data.timestamp
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

return Mention
