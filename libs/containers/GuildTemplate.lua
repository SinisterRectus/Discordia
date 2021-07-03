local Container = require('./Container')

local class = require('../class')

local GuildTemplate, get = class('GuildTemplate', Container)

function GuildTemplate:__init(data, client)
	Container.__init(self, client)
	self._code = data.code
	self._name = data.name
	self._description = data.description
	self._usage_count = data.usage_count
	self._creator_id = data.creator_id
	self._creator = client.state:newUser(data.creator)
	self._created_at = data.created_at
	self._updated_at = data.updated_at
	self._source_guild_id = data.source_guild_id
	self._is_dirty = data.is_dirty
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
