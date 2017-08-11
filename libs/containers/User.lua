local Snowflake = require('containers/abstract/Snowflake')
local constants = require('constants')

local format = string.format
local DEFAULT_AVATARS = constants.DEFAULT_AVATARS

local User, get = require('class')('User', Snowflake)

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

--[[
@method getAvatarURL
@param size: number
@param ext: string
@ret string
]]
function User:getAvatarURL(size, ext)
	local avatar = self._avatar
	if avatar then
		ext = ext or avatar:find('a_') == 1 and 'gif' or 'png'
		if size then
			return format('https://cdn.discordapp.com/avatars/%s/%s.%s?size=%s', self._id, avatar, ext, size)
		else
			return format('https://cdn.discordapp.com/avatars/%s/%s.%s', self._id, avatar, ext)
		end
	else
		return self:getDefaultAvatarURL(size)
	end
end

--[[
@method getDefaultAvatarURL
@param size: number
@ret string
]]
function User:getDefaultAvatarURL(size)
	local avatar = self.defaultAvatar
	if size then
		return format('https://cdn.discordapp.com/embed/avatars/%s.png?size=%s', avatar, size)
	else
		return format('https://cdn.discordapp.com/embed/avatars/%s.png', avatar)
	end
end

--[[
@method getPrivateChannel
@ret PrivateChannel
]]
function User:getPrivateChannel()
	local id = self._id
	local client = self.client
	local channel = client._private_channels:find(function(e) return e._recipient._id == id end)
	if channel then
		return channel
	else
		local data, err = client._api:createDM({recipient_id = id})
		if data then
			return client._private_channels:_insert(data)
		else
			return nil, err
		end
	end
end

--[[
@method send
@param content: string|table
@ret Message
]]
function User:send(content)
	local channel, err = self:getPrivateChannel()
	if channel then
		return channel:send(content)
	else
		return nil, err
	end
end

--[[
@property bot: boolean
]]
function get.bot(self)
	return self._bot or false
end

--[[
@property name: string
]]
function get.name(self)
	return self._username
end

--[[
@property username: string
]]
function get.username(self)
	return self._username
end

--[[
@property discriminator: string
]]
function get.discriminator(self)
	return self._discriminator
end

--[[
@property fullname: string
]]
function get.fullname(self)
	return self._username .. '#' .. self._discriminator
end

--[[
@property avatar: string|nil
]]
function get.avatar(self)
	return self._avatar
end

--[[
@property defaultAvatar: number
]]
function get.defaultAvatar(self)
	return self._discriminator % DEFAULT_AVATARS
end

--[[
@property avatarURL: string
]]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[[
@property defaultAvatarURL: string
]]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

--[[
@property mentionString: string
]]
function get.mentionString(self)
	return format('<@%s>', self._id)
end

return User
