--[=[@c AuditLogEntry x Snowflake ...]=]

local Snowflake = require('containers/abstract/Snowflake')

local enums = require('enums')
local actionType = enums.actionType

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
@r table
@r table
@d ...
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
@r *
@d ...
]=]
function AuditLogEntry:getTarget()
	return targets[self._action_type](self)
end

--[=[
@m getUser
@r User
@d ...
]=]
function AuditLogEntry:getUser()
	return self._parent._parent:getUser(self._user_id)
end

--[=[
@m getMember
@r Member
@d ...
]=]
function AuditLogEntry:getMember()
	return self._parent:getMember(self._user_id)
end

--[=[@p changes table|nil ...]=]
function get.changes(self)
	return self._changes
end

--[=[@p options table|nil ...]=]
function get.options(self)
	return self._options
end

--[=[@p actionType number ...]=]
function get.actionType(self)
	return self._action_type
end

--[=[@p targetId string|nil ...]=]
function get.targetId(self)
	return self._target_id
end

--[=[@p reason string|nil ...]=]
function get.reason(self)
	return self._reason
end

--[=[@p guild Guild ...]=]
function get.guild(self)
	return self._parent
end

return AuditLogEntry
