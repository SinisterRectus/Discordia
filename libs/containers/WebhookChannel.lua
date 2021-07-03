local Snowflake = require('./Snowflake')

local class = require('../class')

local WebhookChannel, get = class('WebhookChannel', Snowflake)

function WebhookChannel:__init(data, client)
	Snowflake.__init(self, data, client)
	self._name = data.name
end

function get:name()
	return self._name
end

return WebhookChannel
