local Snowflake = require('../Snowflake')

local format = string.format

local Webhook, property, method = class('Webhook', Snowflake)
Webhook.__description = "Represents a Discord channel Webhook handle."

function Webhook:__init(data, parent)
	Snowflake.__init(self, data, parent)
	if data.user then -- does not exist if getting by token
		self._user = self._parent._users:get(data.user.id) or self._parent._users:new(data.user)
	end
end

function Webhook:__tostring()
	return format('%s: %s', self.__name, self._name)
end

local function getAvatarUrl(self, size)
	local avatar = self._avatar
	if avatar then
		local ext = avatar:find('a_') == 1 and 'gif' or 'png'
		local fmt = 'https://cdn.discordapp.com/avatars/%s/%s.%s?size=%i'
		return format(fmt, self._id, avatar, ext, size or 1024)
	else
		return 'https://discordapp.com/assets/6debd47ed13483642cf09e832ed0bc1b.png'
	end
end

local function setName(self, name)
	local success, data = self._parent._api:modifyWebhook(self._id, {name = name})
	if success then self._name = data.name end
	return success
end

local function setAvatar(self, avatar)
	local success, data = self._parent._api:modifyWebhook(self._id, {avatar = avatar})
	if success then self._avatar = data.avatar end
	return success
end

local function delete(self)
	return (self._parent._api:deleteWebhook(self._id))
end

property('guildId', '_guild_id', nil, 'string', "Snowflake ID of the guild in which the webhook exists")
property('channelId', '_channel_id', nil, 'string', "Snowflake ID of the channel in which the webhook exists")
property('user', '_user', nil, 'User?', 'The user that created the webhook, if known')
property('token', '_token', nil, 'string', 'The token used to make certain webhook requests')
property('name', '_name', setName, 'string', 'The name of the webhook')
property('avatar', '_avatar', setAvatar, 'string?', "Hash representing the webhook's custom avatar")
property('avatarUrl', getAvatarUrl, nil, 'string', "URL that points to the webhook's avatar")

method('delete', delete, nil, "Permanently deletes the Webhook.", 'HTTP')

return Webhook
