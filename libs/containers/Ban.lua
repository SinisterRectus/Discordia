local Container = require('./Container')
local User = require('./User')

local class = require('../class')
local typing = require('../typing')

local checkType = typing.checkType

local Ban, get = class('Ban', Container)

function Ban:__init(data, client)
	Container.__init(self, client)
	self._guild_id = assert(data.guild_id)
	self._reason = data.reason
	self._user = User(data.user, client)
end

function Ban:__eq(other)
	return self.guildId == other.guildId and self.user.id == other.user.id
end

function Ban:delete(reason)
	local query = reason and {reason = checkType('string', reason)} or nil
	local data, err = self.client.api:removeGuildBan(self.guildId, self.user.id, query)
	if data then
		return true
	else
		return false, err
	end
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
