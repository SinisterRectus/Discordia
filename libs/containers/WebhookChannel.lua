local Snowflake = require('./Snowflake')

local class = require('../class')

local WebhookChannel, get = class('WebhookChannel', Snowflake)

function WebhookChannel:__init(data, client)
	Snowflake.__init(self, data, client)
end

function get:name()
	return self._name
end

return WebhookChannel
