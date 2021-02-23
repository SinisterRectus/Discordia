local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')

local typing = require('../typing')
local class = require('../class')
local enums = require('../enums')
local constants = require('../constants')

local checkEnum = typing.checkEnum
local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension
local format = string.format
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
	return Bitfield(self.flags):hasValue(checkEnum(enums.userFlag, flag))
end

function User:getAvatarURL(ext, size)
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	if self.avatar then
		return self.client.cdn:getUserAvatarURL(self.id, self.avatar, ext, size)
	else
		return self.client.cdn:getDefaultUserAvatarURL(self.defaultAvatar, ext, size)
	end
end

function User:getDefaultAvatarURL(ext, size)
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getDefaultUserAvatarURL(self.defaultAvatar, ext, size)
end

function User:getPrivateChannel()
	return self.client:createDM(self.id)
end

-- TODO: send shortcut

function get:bot()
	return self._bot or false
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
