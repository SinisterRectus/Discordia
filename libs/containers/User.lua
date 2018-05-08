--[=[@c User x Snowflake desc]=]

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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
]=]
function User:sendf(content, ...)
	local channel, err = self:getPrivateChannel()
	if channel then
		return channel:sendf(content, ...)
	else
		return nil, err
	end
end

--[=[@p bot type desc]=]
function get.bot(self)
	return self._bot or false
end

--[=[@p name type desc]=]
function get.name(self)
	return self._username
end

--[=[@p username type desc]=]
function get.username(self)
	return self._username
end

--[=[@p discriminator type desc]=]
function get.discriminator(self)
	return self._discriminator
end

--[=[@p tag type desc]=]
function get.tag(self)
	return self._username .. '#' .. self._discriminator
end

--[=[@p fullname type desc]=]
function get.fullname(self)
	self.client:_deprecated(self.__name, 'fullname', 'tag')
	return self._username .. '#' .. self._discriminator
end

--[=[@p avatar type desc]=]
function get.avatar(self)
	return self._avatar
end

--[=[@p defaultAvatar type desc]=]
function get.defaultAvatar(self)
	return self._discriminator % DEFAULT_AVATARS
end

--[=[@p avatarURL type desc]=]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[=[@p defaultAvatarURL type desc]=]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

--[=[@p mentionString type desc]=]
function get.mentionString(self)
	return format('<@%s>', self._id)
end

--[=[@p mutualGuilds type desc]=]
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
