local class = require('../class')

local Struct = require('./Struct')

local AuditLogOptions, get = class('AuditLogOptions', Struct)

function AuditLogOptions:__init(data)
	Struct.__init(self, data)
	self._type = tonumber(data.type) -- thanks discord
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
