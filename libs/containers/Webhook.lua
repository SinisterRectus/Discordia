local json = require('json')
local enums = require('enums')
local Snowflake = require('containers/abstract/Snowflake')
local User = require('containers/User')
local Resolver = require('client/Resolver')

local defaultAvatar = enums.defaultAvatar

local Webhook, get = require('class')('Webhook', Snowflake)

--[[
@class Webhook x Snowflake

Represents a handle used to send webhook messages to a guild text channel in a
one-way fashion. This class defines methods and properties for managing the
webhook, not for sending messages.
]]
function Webhook:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._user = data.user and self.client._users:_insert(data.user) -- DNE if getting by token
end

function Webhook:_modify(payload)
	local data, err = self.client._api:modifyWebhook(self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[[
@method getAvatarURL
@param size: number
@param ext: string
@ret string

Returns a URL that can be used to view the webhooks's full avatar. If provided,
the size must be a power of 2 while the extension must be a valid image format.
If the webhook does not have a custom avatar, the default URL is returned.
]]
function Webhook:getAvatarURL(size, ext)
	return User.getAvatarURL(self, size, ext)
end

--[[
@method getDefaultAvatarURL
@param size: number
@ret string

Returns a URL that can be used to view the webhooks's default avatar.
]]
function Webhook:getDefaultAvatarURL(size)
	return User.getDefaultAvatarURL(self, size)
end

--[[
@method setName
@tags http
@param name: string
@ret boolean

Sets the webhook's name. This must be between 2 and 32 characters in length.
]]
function Webhook:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setAvatar
@tags http
@param avatar: Base64 Resolveable
@ret boolean

Sets the webhook's avatar. If `nil` is passed, the avatar is removed.
]]
function Webhook:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or json.null})
end

--[[
@method delete
@tags http
@ret boolean

Permanently deletes the webhook. This cannot be undone!
]]
function Webhook:delete()
	local data, err = self.client._api:deleteWebhook(self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@property guildId: string

The ID of the guild in which this webhook exists.
]]
function get.guildId(self)
	return self._guild_id
end

--[[
@property channelId: string

The ID of the channel in which this webhook exists.
]]
function get.channelId(self)
	return self._channel_id
end

--[[
@property user: User|nil

The user that created this webhook.
]]
function get.user(self)
	return self._user
end

--[[
@property token: string

The token that can be used to access this webhook.
]]
function get.token(self)
	return self._token
end

--[[
@property name: string

The name of the webhook. This should be between 2 and 32 characters in length.
]]
function get.name(self)
	return self._name
end

--[[
@property avatar: string|nil

The hash for the webhook's custom avatar, if one is set.
]]
function get.avatar(self)
	return self._avatar
end

--[[
@property avatarURL: string|nil

Equivalent to the result of calling `$:getAvatarURL()`.
]]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[[
@property defaultAvatar: number

The default avatar for the webhook. See the `defaultAvatar` enumeration for
a human-readable representation. This should always be `defaultAvatar.blurple`.
]]
function get.defaultAvatar()
	return defaultAvatar.blurple
end

--[[
@property defaultAvatarURL: string

Equivalent to the result of calling `$:getDefaultAvatarURL()`.
]]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

return Webhook
