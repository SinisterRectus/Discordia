local Container = require('./Container')

local class = require('../class')

local Ban, get = class('Ban', Container)

function Ban:__init(data, client)
	Container.__init(self, client)
	self._guild_id = assert(data.guild_id)
	self._reason = data.reason
	self._user = client.state:newUser(data.user)
end

function Ban:__eq(other)
	return self.guildId == other.guildId and self.user.id == other.user.id
end

function Ban:delete(reason)
	return self.client:removeGuildBan(self.guildId, self.user.id, reason)
end

function Ban:getGuild()
	return self.client:getGuild(self.guildId)
end

function get:reason()
	return self._reason
end

function get:guildId()
	return self._guild_id
end

function get:user()
	return self._user
end

return Ban
