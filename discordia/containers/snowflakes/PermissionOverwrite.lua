local bit = require('bit')
local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local band, bnot = bit.band, bit.bnot
local format = string.format

local PermissionOverwrite, property, method = class('PermissionOverwrite', Snowflake)
PermissionOverwrite.__description = "Represents a Discord guild channel permission overwrite."

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function PermissionOverwrite:__tostring()
	local obj = self.object
	return format('%s: %s', self.__name, obj and obj.name or self._id)
end

local function getGuild(self)
	return self._parent._parent
end

local function getObject(self)
	local guild = self._parent._parent
	if self._type == 'role' then
		return guild._roles:get(self._id)
	else
		return guild:getMember(self._id)
	end
end

local function getName(self)
	local object = self.object
	if self._type == 'role' then
		return object._name
	else
		return object._user._username
	end
end

-- directly accessing both permissions is not exposed
-- because users might confuse this with a role's single-valued permissions
local function _getPermissions(self)
	return Permissions(self._allow), Permissions(self._deny)
end

-- directly setting both permissions is not exposed
-- this prevents allowing and denying the same permission
-- which, apparently, Discord does not prevent
local function _setPermissions(self, allow, deny)
	local channel = self._parent
	local client = channel._parent._parent
	local success = client._api:editChannelPermissions(channel._id, self._id, {
		allow = allow, deny = deny, type = self._type
	})
	if success then self._allow, self._deny = allow, deny end
	return success
end

local function getAllowedPermissions(self)
	return Permissions(self._allow)
end

local function getDeniedPermissions(self)
	return Permissions(self._deny)
end

local function setAllowedPermissions(self, allowed)
	local allow = allowed._value
	local deny = band(bnot(allow), self._deny) -- un-deny the allowed permissions
	return _setPermissions(self, allow, deny)
end

local function setDeniedPermissions(self, denied)
	local deny = denied._value
	local allow = band(bnot(deny), self._allow) -- un-allow the denied permissions
	return _setPermissions(self, allow, deny)
end

local function allowPermissions(self, ...)
	local allowed, denied = _getPermissions(self)
	allowed:enable(...); denied:disable(...)
	return _setPermissions(self, allowed._value, denied._value)
end

local function denyPermissions(self, ...)
	local allowed, denied = _getPermissions(self)
	allowed:disable(...); denied:enable(...)
	return _setPermissions(self, allowed._value, denied._value)
end

local function clearPermissions(self, ...)
	local allowed, denied = _getPermissions(self)
	allowed:disable(...); denied:disable(...)
	return _setPermissions(self, allowed._value, denied._value)
end

local function allowAllPermissions(self)
	local allowed, denied = _getPermissions(self)
	allowed:enableAll(); denied:disableAll()
	return _setPermissions(self, allowed._value, denied._value)
end

local function denyAllPermissions(self)
	local allowed, denied = _getPermissions(self)
	allowed:disableAll(); denied:enableAll()
	return _setPermissions(self, allowed._value, denied._value)
end

local function clearAllPermissions(self)
	local allowed, denied = _getPermissions(self)
	allowed:disableAll(); denied:disableAll()
	return _setPermissions(self, allowed._value, denied._value)
end

local function delete(self)
	local channel = self._parent
	local client = channel._parent._parent
	return (client._api:deleteChannelPermission(channel._id, self._id))
end

property('channel', '_parent', nil, 'GuildChannel', 'The channel to which the overwrite belongs')
property('guild', getGuild, nil, 'Guild', "The guild in which the overwrite exists")
property('object', getObject, nil, 'Role or Member', "The guild role or member object to which the overwrite applies")
property('name', getName, nil, 'string', "Equivalent to the role or member to which the overwrite applies")
property('allowedPermissions', getAllowedPermissions, setAllowedPermissions, 'Permissions', "Object representing permissions that are allowed by the overwrite.")
property('deniedPermissions', getDeniedPermissions, setDeniedPermissions, 'Permissions', "Object representing permissions that are denied by the overwrite.")

method('allowPermissions', allowPermissions, 'flag[, ...]', "Sets permissions for the overwrite by flag to allowed.")
method('denyPermissions', denyPermissions, 'flag[, ...]', "Sets permissions for the overwrite by flag to denied.")
method('clearPermissions', clearPermissions, 'flag[, ...]', "Clears permissions settings for the overwrite by flag.")
method('allowAllPermissions', allowAllPermissions, nil, "Sets all permissions to allowed.")
method('denyAllPermissions', denyAllPermissions, nil, "Sets all permissions to denied.")
method('clearAllPermissions', clearAllPermissions, nil, "Clears the setting of all permissions.")
method('delete', delete, nil, "Deletes the permission overwrite.")

return PermissionOverwrite
