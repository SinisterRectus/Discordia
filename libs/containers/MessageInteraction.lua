local Snowflake = require('./Snowflake')

local class = require('../class')

local MessageInteraction, get = class('MessageInteraction', Snowflake)

function MessageInteraction:__init(data, client)
	Snowflake.__init(self, data, client)
	self._user = client.state:newUser(data.user)
end

function get:name()
	return self._name
end

function get:type()
	return self._type
end

function get:user()
	return self._user
end

return MessageInteraction
