local Snowflake = require('./Snowflake')

local format = string.format

local Webhook, property, method = class('Webhook', Snowflake)
Webhook.__description = "Represents Discord Webhook."

function Webhook:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._id = data.id
	self._guild_id = data.guild_id
	self._channel_id = data.channel_id
	self._user = data.user
	self._user_discriminator = data.user.discriminator
	self._user_id = data.user.id
	self._name = data.name
	self._avatar = data.user.avatar
	self._token = data.token
end

function Webhook:__tostring()
	return format('%s: %s', self.__name, self._token)
end

function Webhook:__eq(other)
	return self.__name == other.__name and self._token == other._token
end

local function create(self)
	return (self._parent._api:createWebhook(self._channel_id, {
		name = self._name, 
		avatar = self._avatar
	}))
end

local function getChannel(self)
	return self._parent._api:getChannelWebhooks(self._channel_id)
end

local function getGuild(self)
	return self._parent._api:getGuildWebhooks(self._guild_id)
end

local function get(self)
	return self._parent._api:getWebhook(self._id)
end

local function getwithToken(self)
	return self._parent._api:getWebhookwithToken(self._token)
end

local function modify(self)
	local success, data = self._parent._api:modifyWebhook(self._id, {
		name = self._name,
		avatar = self._avatar,
	})
	return success
end

local function modifywithToken(self)
	local success, data = self._parent._api:modifyWebhookwithToken(self._id, self._token, {
		name = self._name,
		avatar = self._avatar,
	})
	return success
end

local function delete(self)
	local success, data = self._parent._api:deleteWebhook(self._id)
	return success
end

local function execute(self, payload) -- Not exposed yet, missing header.
	local success, data = self._parent._api:executeWebhook(self._id, self._token, payload)
	return success
end

local function executeSlackCompatible(self, payload)
	local success, data = self._parent._api:executeSlackCompatibleWebhook(self._id, self._token, payload)
	return success
end

local function executeGitHubCompatible(self, payload)
	local success, data = self._parent._api:executeGitHubCompatibleWebhook(self._id, self._token, payload)
	return success
end

property('id', '_id', nil, 'string', "Webhook identifying id.")
property('guild_id', '_guild_id', nil, 'string', "Webhook identifying Guild id.")
property('channel_id', '_channel_id', nil, 'string', "Webhook identifying Channel id.")
property('user', '_user', nil, 'User', "Webhook identifying User Object.")
property('user_id', '_user_id', nil, 'string', "Webhook identifying User id.")
property('user_discriminator', '_user_discriminator', nil, 'string', "Webhook identifying User discriminator.")
property('name', '_name', nil, 'string', "Webhook identifying name.")
property('avatar', '_avatar', nil, 'string', "Webhook identifying avatar.")
property('token', '_token', nil, 'string', "Webhook identifying token.")

method('create', create, nil, "Creates a webhook in the channel.")
method('getChannel', getChannel, nil, "Returns webhooks in the channel.")
method('getGuild', getGuild, nil, "Returns webhooks in the Guild.")
method('get', get, nil, "Returns a webhook by id.")
method('getwithToken', getwithToken, nil, "Returns a webhook by token.")
method('modify', modify, nil, "Modifies the webhook.")
method('modifywithToken', modifywithToken, nil, "Modifies the webhook with the given token.")
method('delete', delete, nil, "Deletes webhook.")
method('executeSlackCompatible', executeSlackCompatible, "payload", "Exectules Slack Webhook.")
method('executeGitHubCompatible', executeGitHubCompatible, nil, "Exectules GitHub Webhook.")

return Webhook
