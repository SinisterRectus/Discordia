local Snowflake = require('./Snowflake')
local Channel = require('./Channel')

local typing = require('../typing')
local class = require('../class')
local enums = require('../enums')
local constants = require('../constants')

local checkEnum = typing.checkEnum
local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtenstion
local band = bit.band
local format = string.format
local CDN_URL = constants.CDN_URL
local DEFAULT_AVATARS = constants.DEFAULT_AVATARS

local User, get = class('User', Snowflake)

function User:__init(data, client)
	Snowflake.__init(self, data, client)
	self._username = data.username
	self._avatar = data.avatar
	self._discriminator = data.discriminator
	self._bot = data.bot
	self._public_flags = data.public_flags
	self._premium_type = data.premium_type
end

function User:hasFlag(flag)
	flag = checkEnum(enums.userFlag, flag)
	return band(self.flags, flag) == flag
end

function User:getAvatarURL(size, ext)
	size = size and checkImageSize(size)
	local avatar = self.avatar
	if avatar then
		ext = ext and checkImageExtension(ext) or avatar:sub(1, 2) == 'a_' and 'gif' or 'png'
		if size then
			return format('%s/avatars/%s/%s.%s?size=%s', CDN_URL, self.id, avatar, ext, size)
		else
			return format('%s/avatars/%s/%s.%s', CDN_URL, self.id, avatar, ext)
		end
	else
		return self:getDefaultAvatarURL(size)
	end
end

function User:getDefaultAvatarURL(size)
	size = size and checkImageSize(size)
	local avatar = self.defaultAvatar
	if size then
		return format('%s/embed/avatars/%s.png?size=%s', CDN_URL, avatar, size)
	else
		return format('%s/embed/avatars/%s.png', CDN_URL, avatar)
	end
end

function User:getPrivateChannel()
	local data, err = self.client.api:createDM {recipient_id = self.id}
	if data then
		return Channel(data, self.client)
	else
		return nil, err
	end
end

function get:bot()
	return not not self._bot
end

function get:name()
	return self._username
end

function get:username()
	return self._username
end

function get:discriminator()
	return self._discriminator
end

function get:tag()
	return self._username .. '#' .. self._discriminator
end

function get:avatar()
	return self._avatar
end

function get:defaultAvatar()
	return self.discriminator % DEFAULT_AVATARS
end

function get:mentionString()
	return format('<@%s>', self.id)
end

function get:flags()
	return self._public_flags or 0
end

function get:premiumType()
	return self._premium_type or 0
end

return User
