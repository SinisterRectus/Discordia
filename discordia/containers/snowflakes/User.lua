local Snowflake = require('../Snowflake')

local format = string.format

local User, accessors = class('User', Snowflake)

accessors.name = function(self) return self.username end

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.bot = not not data.bot
	self:_update(data)
end

function User:_update(data)
	self.avatar = data.avatar or self.avatar
	self.username = data.username or self.username
	self.discriminator = data.discriminator or self.discriminator
end

function User:_loadClientData(data)
	self.email = data.email
	self.verified = data.verified
	self.mfaEnabled = data.mfa_enabled
end

function User:getMembership(guild)
	return guild.members:get(self.id)
end

function User:getAvatarUrl()
	if not self.avatar then return nil end
	return format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

function User:getMentionString()
	return format('<@%s>', self.id)
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
