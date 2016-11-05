local Snowflake = require('../Snowflake')

local format = string.format

local User, property, method = class('User', Snowflake)
User.__description = "Represents a Discord user."

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

function User:__tostring()
	return format('%s: %s', self.__name, self._username)
end

local function getAvatarUrl(self)
	if not self._avatar then return nil end
	return format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self._id, self._avatar)
end

local function getMentionString(self)
	return format('<@%s>', self._id)
end

local function getMembership(self, guild)
	local member = guild._members:get(self._id)
	if not member then
		local success, data = guild._parent._api:getGuildMember(guild._id, self._id)
		if success then member = guild._members:new(data) end
	end
	return member
end

local function sendMessage(self, ...)
	local id = self._id
	local client = self._parent
	local channel = client._private_channels:find('_recipient', function(v) return v._id == id end)
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

property('avatarUrl', getAvatarUrl, nil, 'string', "URL that points to the user's avatar")
property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('avatar', '_avatar', nil, 'string', "Hash representing the user's avatar")
property('name', '_username', nil, 'string', "The user's name (alias of username)")
property('username', '_username', nil, 'string', "The user's name (alias of name)")
property('discriminator', '_discriminator', nil, 'string', "The user's 4-digit discriminator")
property('bot', '_bot', nil, 'boolean', "Whether the user is a bot account")

method('ban', ban, 'guild', "Bans the user from the provided guild.")
method('unban', unban, 'guild', "Unbans the user from the provided guild.")
method('kick', kick, 'guild', "Kicks the user from the provided guild.")
method('sendMessage', sendMessage, 'content[, mentions, tts, nonce]', "Sends a private message to the user.")
method('getMembership', getMembership, 'guild', "Returns the user's Member object for the provided guild.")

return User
