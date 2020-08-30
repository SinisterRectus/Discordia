local Snowflake = require('./Snowflake')

local class = require('../class')

local AuditLogEntry, get = class('AuditLogEntry', Snowflake)

function AuditLogEntry:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = assert(data.guild_id)
	self._target_id = data.target_id
	self._user_id = data.user_id
	self._action_type = data._action_type
	self._reason = data.reason
	-- TODO: changes and options
end

function AuditLogEntry:getChanges() -- TODO
end

function AuditLogEntry:getOptions() -- TODO
end

function AuditLogEntry:getTarget() -- TODO
end

function AuditLogEntry:getUser()
	return self.client:getUser(self.userId)
end

function AuditLogEntry:getGuild()
	return self.client:getGuild(self.guildId)
end

function get:actionType()
	return self._action_type
end

function get:targetId()
	return self._target_id
end

function get:userId()
	return self._user_id
end

function get:reason()
	return self._reason
end

return AuditLogEntry
