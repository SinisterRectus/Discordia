local class = require('../class')

local WebhookGuild, get = class('WebhookGuild')

function WebhookGuild:__init(data)
	self._id = data.id
	self._name = data.name
	self._icon = data.icon
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

return WebhookGuild
