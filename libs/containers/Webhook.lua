local json = require('json')
local enums = require('enums')
local Snowflake = require('containers/abstract/Snowflake')
local User = require('containers/User')
local Resolver = require('client/Resolver')

local defaultAvatar = enums.defaultAvatar

local Webhook, get = require('class')('Webhook', Snowflake)

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
]]
function Webhook:getAvatarURL(size, ext)
	return User.getAvatarURL(self, size, ext)
end

--[[
@method getDefaultAvatarURL
@param size: number
@ret string
]]
function Webhook:getDefaultAvatarURL(size)
	return User.getDefaultAvatarURL(self, size)
end

--[[
@method setName
@param name: string
@ret boolean
]]
function Webhook:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setAvatar
@param avatar: Base64 Resolveable
@ret boolean
]]
function Webhook:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or json.null})
end

--[[
@method delete
@ret boolean
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
]]
function get.guildId(self)
	return self._guild_id
end

--[[
@property channelId: string
]]
function get.channelId(self)
	return self._channel_id
end

--[[
@property user: User|nil
]]
function get.user(self)
	return self._user
end

--[[
@property token: string
]]
function get.token(self)
	return self._token
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property avatar: string|nil
]]
function get.avatar(self)
	return self._avatar
end

--[[
@property avatarURL: string|nil
]]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[[
@property defaultAvatar: number
]]
function get.defaultAvatar()
	return defaultAvatar.blurple
end

--[[
@property defaultAvatarURL: string
]]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

return Webhook
