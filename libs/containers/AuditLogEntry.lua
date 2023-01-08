--[=[
@c AuditLogEntry x Snowflake
@d Represents an entry made into a guild's audit log.
]=]

local Snowflake = require('containers/abstract/Snowflake')

local enums = require('enums')
local actionType = assert(enums.actionType)

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

--[=[
@m getBeforeAfter
@t mem
@r table
@r table
@d Returns two tables of the target's properties before the change, and after the change.
]=]
function AuditLogEntry:getBeforeAfter()
	local before, after = {}, {}
	for k, change in pairs(self._changes) do
		before[k], after[k] = change.old, change.new
	end
	return before, after
end

local function unknown(self)
	return nil, 'unknown audit log action type: ' .. self._action_type
end

local targets = setmetatable({

	[actionType.guildUpdate] = function(self)
		return self._parent
	end,

	[actionType.channelCreate] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.channelUpdate] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.channelDelete] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.channelOverwriteCreate] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.channelOverwriteUpdate] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.channelOverwriteDelete] = function(self)
		return self._parent:getChannel(self._target_id)
	end,

	[actionType.memberKick] = function(self)
		return self._parent._parent:getUser(self._target_id)
	end,

	[actionType.memberPrune] = function()
		return nil
	end,

	[actionType.memberBanAdd] = function(self)
		return self._parent._parent:getUser(self._target_id)
	end,

	[actionType.memberBanRemove] = function(self)
		return self._parent._parent:getUser(self._target_id)
	end,

	[actionType.memberUpdate] = function(self)
		return self._parent:getMember(self._target_id)
	end,

	[actionType.memberRoleUpdate] = function(self)
		return self._parent:getMember(self._target_id)
	end,

	[actionType.roleCreate] = function(self)
		return self._parent:getRole(self._target_id)
	end,

	[actionType.roleUpdate] = function(self)
		return self._parent:getRole(self._target_id)
	end,

	[actionType.roleDelete] = function(self)
		return self._parent:getRole(self._target_id)
	end,

	[actionType.inviteCreate] = function()
		return nil
	end,

	[actionType.inviteUpdate] = function()
		return nil
	end,

	[actionType.inviteDelete] = function()
		return nil
	end,

	[actionType.webhookCreate] = function(self)
		return self._parent._parent._webhooks:get(self._target_id)
	end,

	[actionType.webhookUpdate] = function(self)
		return self._parent._parent._webhooks:get(self._target_id)
	end,

	[actionType.webhookDelete] = function(self)
		return self._parent._parent._webhooks:get(self._target_id)
	end,

	[actionType.emojiCreate] = function(self)
		return self._parent:getEmoji(self._target_id)
	end,

	[actionType.emojiUpdate] = function(self)
		return self._parent:getEmoji(self._target_id)
	end,

	[actionType.emojiDelete] = function(self)
		return self._parent:getEmoji(self._target_id)
	end,

	[actionType.messageDelete] = function(self)
		return self._parent._parent:getUser(self._target_id)
	end,

}, {__index = function() return unknown	end})

--[=[
@m getTarget
@t http?
@r *
@d Gets the target object of the affected entity. The returned object can be: [[Guild]],
[[GuildChannel]], [[User]], [[Member]], [[Role]], [[Webhook]], [[Emoji]], nil
]=]
function AuditLogEntry:getTarget()
	return targets[self._action_type](self)
end

--[=[
@m getUser
@t http?
@r User
@d Gets the user who performed the changes.
]=]
function AuditLogEntry:getUser()
	return self._parent._parent:getUser(self._user_id)
end

--[=[
@m getMember
@t http?
@r Member/nil
@d Gets the member object of the user who performed the changes.
]=]
function AuditLogEntry:getMember()
	return self._parent:getMember(self._user_id)
end

--[=[@p changes table/nil A table of audit log change objects. The key represents
the property of the changed target and the value contains a table of `new` and
possibly `old`, representing the property's new and old value.]=]
function get.changes(self)
	return self._changes
end

--[=[@p options table/nil A table of optional audit log information.]=]
function get.options(self)
	return self._options
end

--[=[@p actionType number The action type. Use the `actionType `enumeration
for a human-readable representation.]=]
function get.actionType(self)
	return self._action_type
end

--[=[@p targetId string/nil The Snowflake ID of the affected entity. Will
be `nil` for certain targets.]=]
function get.targetId(self)
	return self._target_id
end

--[=[@p userId string The Snowflake ID of the user who commited the action.]=]
function get.userId(self)
	return self._user_id
end

--[=[@p reason string/nil The reason provided by the user for the change.]=]
function get.reason(self)
	return self._reason
end

--[=[@p guild Guild The guild in which this audit log entry was found.]=]
function get.guild(self)
	return self._parent
end

return AuditLogEntry
