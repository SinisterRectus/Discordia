--[=[
@c User x Snowflake
@d Represents a single user of Discord, either a human or a bot, outside of any
specific guild's context.
]=]

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
@d Returns a URL that can be used to view the user's full avatar. If provided, the
size must be a power of 2 while the extension must be a valid image format. If
the user does not have a custom avatar, the default URL is returned.
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
@d Returns a URL that can be used to view the user's default avatar.
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
@d Returns a private channel that can be used to communicate with the user. If the
channel is not cached an HTTP request is made to open one.
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
@p content string/table
@r Message
@d Equivalent to `User:getPrivateChannel():send(content)`
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
@d Equivalent to `User:getPrivateChannel():sendf(content)`
]=]
function User:sendf(content, ...)
	local channel, err = self:getPrivateChannel()
	if channel then
		return channel:sendf(content, ...)
	else
		return nil, err
	end
end

--[=[@p bot boolean Whether this user is a bot.]=]
function get.bot(self)
	return self._bot or false
end

--[=[@p name string Equivalent to `User.username`.]=]
function get.name(self)
	return self._username
end

--[=[@p username string The name of the user. This should be between 2 and 32 characters in length.]=]
function get.username(self)
	return self._username
end

--[=[@p discriminator number The discriminator of the user. This is a 4-digit string that is used to
discriminate the user from other users with the same username.]=]
function get.discriminator(self)
	return self._discriminator
end

--[=[@p tag string The user's username and discriminator concatenated by an `#`.]=]
function get.tag(self)
	return self._username .. '#' .. self._discriminator
end

function get.fullname(self)
	self.client:_deprecated(self.__name, 'fullname', 'tag')
	return self._username .. '#' .. self._discriminator
end

--[=[@p avatar string/nil The hash for the user's custom avatar, if one is set.]=]
function get.avatar(self)
	return self._avatar
end

--[=[@p defaultAvatar number The user's default avatar. See the `defaultAvatar` enumeration for a
human-readable representation.]=]
function get.defaultAvatar(self)
	return self._discriminator % DEFAULT_AVATARS
end

--[=[@p avatarURL string Equivalent to the result of calling `User:getAvatarURL()`.]=]
function get.avatarURL(self)
	return self:getAvatarURL()
end

--[=[@p defaultAvatarURL string Equivalent to the result of calling `User:getDefaultAvatarURL()`.]=]
function get.defaultAvatarURL(self)
	return self:getDefaultAvatarURL()
end

--[=[@p mentionString string A string that, when included in a message content, may resolve as user
notification in the official Discord client.]=]
function get.mentionString(self)
	return format('<@%s>', self._id)
end

--[=[@p mutualGuilds FilteredIterable A iterable cache of all guilds where this user shares a membership with the
current user. The guild must be cached on the current client and the user's
member object must be cached in that guild in order for it to appear here.]=]
local _mutual_guilds = setmetatable({}, {__mode = 'v'})
function get.mutualGuilds(self)
	if not _mutual_guilds[self] then
		local id = self._id
		_mutual_guilds[self] = FilteredIterable(self.client._guilds, function(g)
			return g._members:get(id)
		end)
	end
	return _mutual_guilds[self]
end

return User
