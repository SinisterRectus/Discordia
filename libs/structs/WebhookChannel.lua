local class = require('../class')

local WebhookChannel, get = class('WebhookChannel')

function WebhookChannel:__init(data)
	self._id = data.id
	self._name = data.name
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

return WebhookChannel
