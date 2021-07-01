local class = require('../class')

local InviteChannel, get = class('InviteChannel')

function InviteChannel:__init(data)
	self._id = data.id
	self._name = data.name
	self._type = data.type
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

function get:type()
	return self._type
end

return InviteChannel
