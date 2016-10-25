local Snowflake = require('../Snowflake')

local User, accessors = class('User', Snowflake)

accessors.name = function(self) return self.username end

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.bot = not not data.bot
	self:update(data)
end

function User:update(data)
	self.avatar = data.avatar or self.avatar
	self.username = data.username or self.username
	self.discriminator = data.discriminator or self.discriminator
end

function User:getMembership(guild)
	return guild:getMemberById(self.id)
end

function User:getAvatarUrl()
	if not self.avatar then return nil end
	return string.format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

function User:getMentionString()
	return string.format('<@%s>', self.id)
end

function User:ban(guild, messageDeleteDays)
	return guild:banUser(self, messageDeleteDays)
end

function User:unban(guild)
	return guild:unbanUser(self)
end

function User:kick(guild)
	return guild:kickUser(self)
end

return User
