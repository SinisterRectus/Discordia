local Snowflake = require('../Snowflake')

local Member, accessors = class('Member', Snowflake)
Member.status = 'offline'

accessors.name = function(self) return self.nick or self.user.username end
accessors.guild = function(self) return self.parent end
accessors.nickname = function(self) return self.nick end

accessors.id = function(self) return self.user.id end
accessors.bot = function(self) return self.user.bot end
accessors.avatar = function(self) return self.user.avatar end
accessors.username = function(self) return self.user.username end
accessors.discriminator = function(self) return self.user.discriminator end

function Member:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.deaf = data.deaf
	self.mute = data.mute
	self.joinedAt = data.joined_at
	self.user = self.client:getUserById(data.user.id) or self.client.users:new(data.user)
	self:update(data)
end

function Member:__tostring()
	if self.nick then
		return string.format('%s: %s (%s)', self.__name, self.user.username, self.nick)
	else
		return string.format('%s: %s', self.__name, self.user.username)
	end
end

function Member:update(data)
	self.nick = data.nick
	self.roles = data.roles -- raw table of IDs
end

function Member:createPresence(data)
	self.status = data.status
	if self.game and data.game then
		for k, v in pairs(self.game) do
			self.game[k] = data.game[k]
		end
	else
		self.game = data.game
	end
end

function Member:updatePresence(data)
	self:createPresence(data)
	self.user:update(data.user)
end

function Member:getMembership(guild)
	return guild:getMemberById(self.id)
end

function Member:getAvatarUrl()
	if not self.avatar then return nil end
	return string.format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

function Member:getMentionString()
	return string.format('<@%s>', self.id)
end

return Member
