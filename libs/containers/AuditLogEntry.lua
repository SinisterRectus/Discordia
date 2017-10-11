local Snowflake = require('containers/abstract/Snowflake')

local AuditLogEntry, get = require('class')('AuditLogEntry', Snowflake)

function AuditLogEntry:__init(data, parent)
	Snowflake.__init(self, data, parent)
	if data.changes then
		for i, change in ipairs(data.changes) do
			data.changes[change.key] = change
			data.changes[i] = nil
			change.key = nil
			change.old = change.old_value
			change.new = change.new_value
			change.old_value = nil
			change.new_value = nil
		end
		self._changes = data.changes
	end
	self._options = data.options
end

function AuditLogEntry:getBeforeAfter()
	local before, after = {}, {}
	for k, change in pairs(self._changes) do
		before[k], after[k] = change.old, change.new
	end
	return before, after
end

function AuditLogEntry:getTarget()
	local type = self._action_type
	if type < 10 then
		return self._parent
	elseif type < 20 then
		return self._parent:getChannel(self._target_id)
	elseif type < 30 then
		return self._parent:getMember(self._target_id)
	elseif type < 40 then
		return self._parent:getRole(self._target_id)
	elseif type < 50 then
		return nil -- invite
	elseif type < 60 then
		return self._parent._parent:getWebhook(self._target_id)
	elseif type < 70 then
		return self._parent:getEmoji(self._target_id)
	elseif type < 80 then
		return self._parent._parent:getUser(self._target_id)
	else
		return nil, 'Unknown audit log action type: ' .. type
	end
end

function AuditLogEntry:getUser()
	return self._parent._parent:getUser(self._user_id)
end

function AuditLogEntry:getMember()
	return self._parent:getMember(self._user_id)
end

function get.changes(self)
	return self._changes
end

function get.options(self)
	return self._options
end

function get.actionType(self)
	return self._action_type
end

function get.reason(self)
	return self._reason
end

function get.guild(self)
	return self._parent
end

return AuditLogEntry
