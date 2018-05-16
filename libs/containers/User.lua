--[=[@c User x Snowflake ...]=]

local Snowflake = require('containers/abstract/Snowflake')
local FilteredIterable = require('iterables/FilteredIterable')
local constants = require('constants')

local format = string.format
local DEFAULT_AVATARS = constants.DEFAULT_AVATARS

local User, get = require('class')('User', Snowflake)

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

--[=[
@m getAvatarURL
@op size number
@op ext string
@r string
@d ...
]=]
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

--[=[
@m getDefaultAvatarURL
@op size number
@r string
@d ...
]=]
function User:getDefaultAvatarURL(size)
	local avatar = self.defaultAvatar
	if size then
		return format('https://cdn.discordapp.com/embed/avatars/%s.png?size=%s', avatar, size)
	else
		return format('https://cdn.discordapp.com/embed/avatars/%s.png', avatar)
	end
end

--[=[
@m getPrivateChannel
@r PrivateChannel
@d ...
]=]
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

--[=[
@m send
@p content string|table
@r Message
@d ...
]=]
function User:send(content)
	local channel, err = self:getPrivateChannel()
	if channel then
		return channel:send(content)
	else
		return nil, err
	end
end

--[=[
@m sendf
@p content string
@r Message
@d ...
]=]
function User:sendf(content, ...)
	local channel, err = self:getPrivateChannel()
	if channel then
		return channel:sendf(content, ...)
	else
		return nil, err
	end
end

--[=[@p bot boolean ...]=]
function get.bot(self)
	return self._bot or false
end

--[=[@p name string ...]=]
function get.name(self)
	return self._username
end

--[=[@p username string ...]=]
function get.username(self)
	return self._username
end

--[=[@p discriminator number ...]=]
function get.discriminator(self)
	return self._discriminator
end

--[=[@p tag string ...]=]
function get.tag(self)
	return self._username .. '#' .. self._discriminator
end

--[=[@p fullname string ...]=]
function get.fullname(self)
	self.client:_deprecated(self.__name, 'fullname', 'tag')
	return self._username .. '#' .. self._discriminator
end

--[=[@p avatar string|nil ...]=]
function get.avatar(self)
	return self._avatar
end

--[=[@p defaultAvatar number ...]=]
function get.defaultAvatar(self)
	return self._discriminator % DEFAULT_AVATARS
end

--[=[@p avatarURL string ...]=]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[=[@p defaultAvatarURL string ...]=]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

--[=[@p mentionString string ...]=]
function get.mentionString(self)
	return format('<@%s>', self._id)
end

--[=[@p mutualGuilds FilteredIterable ...]=]
function get.mutualGuilds(self)
	if not self._mutual_guilds then
		local id = self._id
		self._mutual_guilds = FilteredIterable(self.client._guilds, function(g)
			return g._members:get(id)
		end)
	end
	return self._mutual_guilds
end

return User
