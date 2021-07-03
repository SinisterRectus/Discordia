local Snowflake = require('./Snowflake')

local class = require('../class')

local InviteChannel, get = class('InviteChannel', Snowflake)

function InviteChannel:__init(data, client)
	Snowflake.__init(self, data, client)
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
