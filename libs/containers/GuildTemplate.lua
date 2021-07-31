local Container = require('./Container')

local class = require('../class')

local GuildTemplate, get = class('GuildTemplate', Container)

function GuildTemplate:__init(data, client)
	Container.__init(self, data, client)
	self._creator = client.state:newUser(data.creator)
end

function GuildTemplate:__eq(other)
	return self.code == other.code
end

function GuildTemplate:toString()
	return self.code
end

function GuildTemplate:delete()
	return self.client:deleteGuildTemplate(self.guildId, self.code)
end

function GuildTemplate:modify(payload)
	return self.client:modifyGuildTemplate(self.guildId, self.code, payload)
end

function GuildTemplate:sync()
	return self.client:syncGuildTemplate(self.guildId, self.code)
end

function get:code()
	return self._code
end

function get:name()
	return self._name
end

function get:description()
	return self._description
end

function get:usageCount()
	return self._usage_count
end

function get:creatorId()
	return self._creator_id
end

function get:creator()
	return self._creator
end

function get:createdAt()
	return self._created_at
end

function get:updatedAt()
	return self._updated_at
end

function get:guildId()
	return self._source_guild_id
end

function get:isDirty()
	return self._is_dirty
end

return GuildTemplate
