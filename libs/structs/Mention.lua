local class = require('../class')

local Mention, get = class('Mention')

function Mention:__init(data)
	self._id = data.id -- user, channel, role, emoji
	self._type = data.type -- all
	self._raw = data.raw -- all
	self._animated = data.animated -- emoji
	self._name = data.name -- emoji
	self._timestamp = data.timestamp -- timestamp
	self._style = data.style -- timestamp
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
