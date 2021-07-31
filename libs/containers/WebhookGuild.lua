local Snowflake = require('./Snowflake')

local class = require('../class')
local typing = require('../typing')

local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize

local WebhookGuild, get = class('WebhookGuild', Snowflake)

function WebhookGuild:__init(data, client)
	Snowflake.__init(self, data, client)
end

function WebhookGuild:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Guild has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildIconURL(self.id, self.icon, ext, size)
end

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

return WebhookGuild
