local bit = require('bit')
local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor

local PermissionOverwrite, property = class('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

property('channel', '_parent', nil, 'Guild[Text|Voice]Channel', 'The channel to which the overwrite belongs')

property('guild', function(self)
	return self._parent._parent
end, nil, 'Guild', "The guild in which the overwrite exists")

property('object', function(self)
	if self._type == 'role' then
		return self._parent._parent._roles:get(self._id)
	else
		return self._parent._parent._members:get(self._id)
	end
end, nil, 'Role or Member', "The guild role or member object to which the overwrite applies")

property('name', function(self)
	return self.object._name
end, nil, 'string', "Equivalent to the role or member to which the overwrite applies")

local function getAllowedPermissions(self)
	return Permissions(self._allow)
end

local function getDeniedPermissions(self)
	return Permissions(self._deny)
end

local function setAllowedPermissions(self, allowed)
	local allow = allowed._value
	local deny = band(bnot(allow), self._deny)
	return setPermissions(self, allow, deny)
end

local function setDeniedPermissions(self, denied)
	local deny = denied._value
	local allow = band(bnot(deny), self._allow)
	return setPermissions(self, allow, deny)
end

property('allowedPermissions', getAllowedPermissions, setAllowedPermissions, 'Permissions', "The permissions that are allowed by the ovewrite.")
property('deniedPermissions', getDeniedPermissions, setDeniedPermissions, 'Permissions', "The permissions that are denied by the ovewrite.")

function PermissionOverwrite:_update(data)
	self._allow = data.allow
	self._deny = data.deny
end

local function getPermissions(self) -- not exposed
	return Permissions(self._allow), Permissions(self._deny)
end

local function setPermissions(self, allow, deny) -- not exposed
	local channel = self._parent
	local client = channel._parent._parent
	local success, data = client._api:editChannelPermissions(channel._id, self._id, {
		allow = allow, deny = deny, type = self._type
	})
	if success then self._allow, self._deny = allow, deny end
	return success
end

function PermissionOverwrite:permissionIsAllowed(...)
	local allowed = self:getAllowedPermissions()
	return allowed:has(...)
end

function PermissionOverwrite:permissionIsDenied(...)
	local denied = self:getDeniedPermissions()
	return denied:has(...)
end

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
	local channel = self._parent
	local client = channel._parent._parent
	local success, data = client._api:deleteChannelPermission(channel._id, self._id)
	return success
end

return PermissionOverwrite
