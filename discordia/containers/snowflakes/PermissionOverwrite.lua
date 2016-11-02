local bit = require('bit')
local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor

local PermissionOverwrite, get, set = class('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

get('channel', '_parent')

get('guild', function(self)
	return self._parent._parent
end)

get('object', function(self)
	if self._type == 'role' then
		return self._parent._parent._roles:get(self._id)
	else
		return self._parent._parent._members:get(self._id)
	end
end)

get('name', function(self)
	return self.object._name
end)

function PermissionOverwrite:_update(data)
	self._allow = data.allow
	self._deny = data.deny
end

get('permissions', function(self)
	return Permissions(self._allow), Permissions(self._deny)
end)

get('allowedPermissions', function(self)
	return Permissions(self._allow)
end)

get('deniedPermissions', function(self)
	return Permissions(self._deny)
end)

local function setPermissions(self, allow, deny)
	local success, data = self.client._api:editChannelPermissions(self._parent._id, self._id, {
		allow = allow, deny = deny, type = self._type
	})
	if success then self._allow, self._deny = allow, deny end
	return success
end

set('allowedPermissions', function(self, allowed)
	local allow = allowed._value
	local deny = band(bnot(allow), self._deny)
	return setPermissions(self, allow, deny)
end)

set('deniedPermissions', function(self, denied)
	local deny = denied._value
	local allow = band(bnot(deny), self._allow)
	return setPermissions(self, allow, deny)
end)

function PermissionOverwrite:allowPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:denyPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:clearPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:delete()
	local success, data = self.client._api:deleteChannelPermission(self._parent._id, self._id)
	return success
end

return PermissionOverwrite
