local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local band, bnot = bit.band, bit.bnot

local PermissionOverwrite, get = require('class')('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function PermissionOverwrite:delete()
	local data, err = self.client._api:deleteChannelPermission(self._parent._id, self._id)
	if data then
		local cache = self._parent._permission_overwrites
		if cache then
			cache:_delete(self._id)
		end
		return true
	else
		return false, err
	end
end

function PermissionOverwrite:getObject()
	local guild = self._parent._parent
	if self._type == 'role' then
		return guild:getRole(self._id)
	elseif self._type == 'member' then
		return guild:getMember(self._id)
	end
end

local function getPermissions(self)
	return Permissions(self._allow), Permissions(self._deny)
end

local function setPermissions(self, allow, deny)
	local data, err = self.client._api:editChannelPermissions(self._parent._id, self._id, {
		allow = allow, deny = deny, type = self._type
	})
	if data then
		return true
	else
		return false, err
	end
end

function PermissionOverwrite:getAllowedPermissions()
	return Permissions(self._allow)
end

function PermissionOverwrite:getDeniedPermissions()
	return Permissions(self._deny)
end

function PermissionOverwrite:setAllowedPermissions(allowed)
	local allow = Resolver.permissions(allowed)
	local deny = band(bnot(allow), self._deny) -- un-deny the allowed permissions
	return setPermissions(self, allow, deny)
end

function PermissionOverwrite:setDeniedPermissions(denied)
	local deny = Resolver.permissions(denied)
	local allow = band(bnot(deny), self._allow) -- un-allow the denied permissions
	return setPermissions(self, allow, deny)
end

function PermissionOverwrite:allowPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:denyPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:clearPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

function get.type(self)
	return self._type
end

function get.channel(self)
	return self._parent
end

function get.guild(self)
	return self._parent._parent
end

function get.allowedPermissions(self)
	return self._allow
end

function get.deniedPermissions(self)
	return self._deny
end

return PermissionOverwrite
