local class = require('../class')

local AuditLogOptions, get = class('AuditLogOptions')

function AuditLogOptions:__init(data)
	self._delete_member_days = data.delete_member_days
	self._members_removed = data.members_removed
	self._channel_id = data.channel_id
	self._message_id = data.message_id
	self._count = data.count
	self._id = data.id
	self._type = tonumber(data.type) -- thanks discord
	self._role_name = data.role_name
end

function get:deleteMemberDays()
	return self._delete_member_days
end

function get:membersRemoved()
	return self._members_removed
end

function get:channelId()
	return self._channel_id
end

function get:messageId()
	return self._message_id
end

function get:count()
	return self._count
end

function get:id()
	return self._id
end

function get:type()
	return self._type
end

function get:roleName()
	return self._role_name
end

return AuditLogOptions
