local Container = require('./Container')
local Bitfield = require('../utils/Bitfield')

local json = require('json')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local checkEnum = typing.checkEnum

local PermissionOverwrite, get = class('PermissionOverwrite', Container)

function PermissionOverwrite:__init(data, client)
	Container.__init(self, client)
	self._id = data.id
	self._type = data.type
	self._allow = data.allow
	self._deny = data.deny
	self._channel_id = assert(data.channel_id)
end

function PermissionOverwrite:__eq(other)
	return self.channelId == other.channelId and self.id == other.id
end

function PermissionOverwrite:toString()
	return self.channelId .. ':' .. self.id
end

function PermissionOverwrite:delete()
	return self.client:deleteChannelPermission(self.channelId, self.id)
end

function PermissionOverwrite:getChannel()
	return self.client:getChannel(self.channelId)
end

function PermissionOverwrite:setPermissions(allowed, denied)
	return self.client:editChannelPermissions(self.channelId, self.id, {
		type = self.type,
		allowedPermissions = allowed or json.null,
		deniedPermissions = denied or json.null,
	})
end

function PermissionOverwrite:allowPermissions(...)
	local allowed = Bitfield(self.allowedPermissions)
	local denied = Bitfield(self.deniedPermissions)
	for i = 1, select('#', ...) do
		local v = checkEnum(enums.permission, select(i, ...))
		allowed:enableValue(v)
		denied:disableValue(v)
	end
	return self:setPermissions(allowed, denied)
end

function PermissionOverwrite:denyPermissions(...)
	local allowed = Bitfield(self.allowedPermissions)
	local denied = Bitfield(self.deniedPermissions)
	for i = 1, select('#', ...) do
		local v = checkEnum(enums.permission, select(i, ...))
		allowed:disableValue(v)
		denied:enableValue(v)
	end
	return self:setPermissions(allowed, denied)
end

function PermissionOverwrite:clearPermissions(...)
	local allowed = Bitfield(self.allowedPermissions)
	local denied = Bitfield(self.deniedPermissions)
	for i = 1, select('#', ...) do
		local v = checkEnum(enums.permission, select(i, ...))
		allowed:disableValue(v)
		denied:disableValue(v)
	end
	return self:setPermissions(allowed, denied)
end

function get:id()
	return self._id
end

function get:type()
	return self._type
end

function get:allowedPermissions()
	return self._allow
end

function get:deniedPermissions()
	return self._deny
end

function get:channelId()
	return self._channel_id
end

return PermissionOverwrite
