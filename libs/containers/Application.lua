local Snowflake = require('./Snowflake')
local Team = require('./Team')

local class = require('../class')
local typing = require('../typing')

local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension

local Application, get = class('Application', Snowflake)

function Application:__init(data, client)
	Snowflake.__init(self, data, client)
	self._owner = data.owner and client.state:newUser(data.owner)
	self._team = data.team and Team(data.team, client)
end

function Application:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Application has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getApplicationIconURL(self.id, self.icon, ext, size)
end

function Application:getCoverURL(ext, size)
	if not self.coverImage then
		return nil, 'Application has no cover'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getApplicationCoverURL(self.id, self.coverImage, ext, size)
end

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

function get:description()
	return self._description
end

function get:rpcOrigins()
	return self._rpc_origins
end

function get:botPublic()
	return self._bot_public or false
end

function get:botRequreCodeGrant()
	return self._bot_require_code_grant or false
end

function get:termsOfServiceURL()
	return self._terms_of_service_url
end

function get:privacyPolicyURL()
	return self._privacy_policy_url
end

function get:owner()
	return self._owner
end

function get:summary()
	return self._summary
end

function get:verifyKey()
	return self._verify_key
end

function get:team()
	return self._team
end

function get:guildId()
	return self._guild_id
end

function get:primarySKUId()
	return self._primary_sku_id
end

function get:slug()
	return self._slug
end

function get:coverImage()
	return self._cover_image
end

function get:flags()
	return self._flags
end

return Application
