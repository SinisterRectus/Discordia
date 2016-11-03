local Snowflake = require('../Snowflake')

local format = string.format

local User, property = class('User', Snowflake)

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

property('avatar', '_avatar', nil, 'string', "Hash representing the user's avatar")
property('name', '_username', nil, 'string', "The user's name (alias of username)")
property('username', '_username', nil, 'string', "The user's name (alias of name)")
property('discriminator', '_discriminator', nil, 'string', "The user's 4-digit discriminator")
property('bot', '_bot', nil, 'boolean', "Whether the user is a bot account")

property('avatarUrl', function(self)
	if not self._avatar then return nil end
	return format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self._id, self._avatar)
end, nil, 'string', "URL that points to the user's avatar")

property('mentionString', function(self)
	return format('<@%s>', self._id)
end, nil, 'string', "Raw string that is parsed by Discord into a user mention")

function User:__tostring()
	return format('%s: %s', self.__name, self._username)
end

function User:getMembership(guild)
	local member = guild._members:get(self._id)
	if not member then
		local success, data = guild._parent._api:getGuildMember(guild._id, self._id)
		if success then member = guild._members:new(data) end
	end
	return member
end

function User:sendMessage(...)
	local id = self._id
	local client = self._parent
	local channel = client._private_channels:find('_recipient', function(v) return v._id == id end)
	if not channel then
		local success, data = client._api:createDM({recipient_id = id})
		if success then channel = client._private_channels:new(data) end
	end
	if channel then return channel:sendMessage(...) end
end

function User:ban(guild, days)
	return guild:banUser(self, days)
end

function User:unban(guild)
	return guild:unbanUser(self)
end

function User:kick(guild)
	return guild:kickUser(self)
end

return User
