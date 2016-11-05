local bit = require('bit')
local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor

local PermissionOverwrite, property, method = class('PermissionOverwrite', Snowflake)
PermissionOverwrite.__description = "Represents a Discord guild channel permission overwrite."

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

local function getGuild(self)
	return self._parent._parent
end

local function getObject(self)
	if self._type == 'role' then
		return self._parent._parent._roles:get(self._id)
	else
		return self._parent._parent._members:get(self._id)
	end
end

local function getName(self)
	return self.object._name
end

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

local function permissionIsAllowed(self, ...)
	local allowed = self:getAllowedPermissions()
	return allowed:has(...)
end

local function permissionIsDenied(self, ...)
	local denied = self:getDeniedPermissions()
	return denied:has(...)
end

local function allowPermission(self, ...)
	local allowed, denied = self:getPermissions()
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

local function denyPermission(self, ...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed._value, denied._value)
end

local function clearPermission(self, ...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

local function allowAllPermissions(self)
	local allowed, denied = self:getPermissions()
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

local function denyAllPermissions(self)
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed._value, denied._value)
end

local function clearAllPermissions(self)
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

local function delete(self)
	local channel = self._parent
	local client = channel._parent._parent
	local success, data = client._api:deleteChannelPermission(channel._id, self._id)
	return success
end

property('channel', '_parent', nil, 'Guild[Text|Voice]Channel', 'The channel to which the overwrite belongs')
property('guild', getGuild, nil, 'Guild', "The guild in which the overwrite exists")
property('object', getObject, nil, 'Role or Member', "The guild role or member object to which the overwrite applies")
property('name', getName, nil, 'string', "Equivalent to the role or member to which the overwrite applies")
property('allowedPermissions', getAllowedPermissions, setAllowedPermissions, 'Permissions', "The permissions that are allowed by the overwrite.")
property('deniedPermissions', getDeniedPermissions, setDeniedPermissions, 'Permissions', "The permissions that are denied by the overwrite.")

method('permissionIsAllowed', permissionIsAllowed, 'flag[, ...]', "Returns a boolean indicating whether a permission or permissions is/are allowed.")
method('permissionIsDenied', permissionIsDenied, 'flag[, ...]', "Returns a boolean indicating whether a permission or permissions is/are denied.")
method('allowPermission', allowPermission, 'flag[, ...]', "Sets a permission or permissions to allowed.")
method('denyPermission', denyPermission, 'flag[, ...]', "Sets a permission or permissions to denied.")
method('clearPermission', clearPermission, 'flag[, ...]', "Clears the setting of a permission.")
method('allowAllPermissions', allowAllPermissions, nil, "Sets all permissions to allowed.")
method('denyAllPermissions', denyAllPermissions, nil, "Sets all permissions to denied.")
method('clearAllPermissions', clearAllPermissions, nil, "Clears the setting of all permissions.")
method('delete', delete, nil, "Permanently deletes the permission overwrite.")

return PermissionOverwrite
