local Snowflake = require('./Snowflake')

local class = require('../class')
local helpers = require('../helpers')

local readOnly = helpers.readOnly

local AuditLogEntry, get = class('AuditLogEntry', Snowflake)

function AuditLogEntry:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = assert(data.guild_id)
	self._target_id = data.target_id
	self._user_id = data.user_id
	self._action_type = data._action_type
	self._reason = data.reason
	self._changes = data.changes
	self._options = data.options
end

function AuditLogEntry:getUser()
	return self.client:getUser(self.userId)
end

function AuditLogEntry:getMember()
	return self.client:getGuildMember(self.guildId, self.userId)
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

function get:guildId()
	return self._guild_id
end

function get:reason()
	return self._reason
end

function get:changes()
	return readOnly(self._changes)
end

function get:options()
	return readOnly(self._options)
end

return AuditLogEntry
