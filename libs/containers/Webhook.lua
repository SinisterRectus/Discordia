--[=[@c Webhook x Snowflake ...]=]

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

--[=[
@m getAvatarURL
@op size number
@op ext string
@r string
@d ...
]=]
function Webhook:getAvatarURL(size, ext)
	return User.getAvatarURL(self, size, ext)
end

--[=[
@m getDefaultAvatarURL
@op size number
@r string
@d ...
]=]
function Webhook:getDefaultAvatarURL(size)
	return User.getDefaultAvatarURL(self, size)
end

--[=[
@m setName
@p name string
@r boolean
@d ...
]=]
function Webhook:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setAvatar
@p avatar Base64-Resolvable
@r boolean
@d ...
]=]
function Webhook:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or json.null})
end

--[=[
@m delete
@r boolean
@d ...
]=]
function Webhook:delete()
	local data, err = self.client._api:deleteWebhook(self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[=[@p guildId string ...]=]
function get.guildId(self)
	return self._guild_id
end

--[=[@p channelId string ...]=]
function get.channelId(self)
	return self._channel_id
end

--[=[@p user User|nil ...]=]
function get.user(self)
	return self._user
end

--[=[@p token string ...]=]
function get.token(self)
	return self._token
end

--[=[@p name string ...]=]
function get.name(self)
	return self._name
end

--[=[@p avatar string|nil ...]=]
function get.avatar(self)
	return self._avatar
end

--[=[@p avatarURL string ...]=]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[=[@p defaultAvatar number ...]=]
function get.defaultAvatar()
	return defaultAvatar.blurple
end

--[=[@p defaultAvatarURL string ...]=]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

return Webhook
