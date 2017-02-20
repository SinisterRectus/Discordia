local Snowflake = require('../Snowflake')

local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local User, property, method = class('User', Snowflake)
User.__description = "Represents a Discord user."

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function User:__tostring()
	return format('%s: %s', self.__name, self._username)
end

local defaultAvatars = {
	'6debd47ed13483642cf09e832ed0bc1b',
	'322c936a8c8be1b803cd94861bdfa868',
	'dd4dbc0016779df1378e7812eabaa04d',
	'0e291f67c9274a1abdddeb3fd919cbaa',
	'1cbd08c76f8af6dddce02c5138971129',
}

local function getDefaultAvatar(self)
	return defaultAvatars[self._discriminator % #defaultAvatars + 1]
end

local function getDefaultAvatarUrl(self)
	return format('https://discordapp.com/assets/%s.png', getDefaultAvatar(self))
end

local function getAvatarUrl(self, size)
	local avatar = self._avatar
	if avatar then
		local ext = avatar:find('a_') == 1 and 'gif' or 'png'
		local fmt = 'https://cdn.discordapp.com/avatars/%s/%s.%s?size=%i'
		return format(fmt, self._id, avatar, ext, size or 1024)
	else
		return getDefaultAvatarUrl(self)
	end
end

local function getMentionString(self)
	return format('<@%s>', self._id)
end

local function getMembership(self, guild)
	if self._discriminator == '0000' then
		return nil
	elseif guild._member_count == guild._members.count then
		return guild:getMember('id', self._id) -- cache only
	else
		return guild:getMember(self._id) -- uses HTTP fallback
	end
end

local function sendMessage(self, ...)
	local id = self._id
	local client = self._parent
	local channel = client._private_channels:find(function(v) return v._recipient._id == id end)
	if not channel then
		local success, data = client._api:createDM({recipient_id = id})
		if success then channel = client._private_channels:new(data) end
	end
	if channel then return channel:sendMessage(...) end
end

local function ban(self, guild, days)
	return guild:banUser(self, days)
end

local function unban(self, guild)
	return guild:unbanUser(self)
end

local function kick(self, guild)
	return guild:kickUser(self)
end

local function getMutualGuilds(self)
	return wrap(function()
		local id = self._id
		for guild in self._parent._guilds:iter() do
			if guild._members:get(id) then
				yield(guild)
			end
		end
	end)
end

property('avatar', '_avatar', nil, 'string', "Hash representing the user's avatar")
property('avatarUrl', getAvatarUrl, nil, 'string', "URL that points to the user's avatar")
property('defaultAvatar', getDefaultAvatar, nil, 'string', "Hash representing the user's default avatar")
property('defaultAvatarUrl', getDefaultAvatarUrl, nil, 'string', "URL that points to the user's default avatar")
property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('name', '_username', nil, 'string', "The user's name (alias of username)")
property('username', '_username', nil, 'string', "The user's name (alias of name)")
property('discriminator', '_discriminator', nil, 'string', "The user's 4-digit discriminator")
property('bot', '_bot', function(self) return self._bot or false end, 'boolean', "Whether the user is a bot account")
property('mutualGuilds', getMutualGuilds, nil, 'function', "Iterator for guilds in which both the user and client user share membership")

method('ban', ban, 'guild[, days]', "Bans the user from a guild and optionally deletes their messages from 1-7 days.")
method('unban', unban, 'guild', "Unbans the user from the provided guild.")
method('kick', kick, 'guild', "Kicks the user from the provided guild.")
method('sendMessage', sendMessage, 'content', "Sends a private message to the user.")
method('getMembership', getMembership, 'guild', "Returns the user's Member object for the provided guild.")

return User
