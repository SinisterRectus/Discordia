--[=[
@c PermissionOverwrite x Snowflake
@d Represents an object that is used to allow or deny specific permissions for a
role or member in a Discord guild channel.
]=]

local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local PermissionOverwrite, get = require('class')('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

--[=[
@m delete
@t http
@r boolean
@d Deletes the permission overwrite. This can be undone by creating a new version of
the same overwrite.
]=]
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

--[=[
@m getObject
@t http?
@r Role/Member
@d Returns the object associated with this overwrite, either a role or member.
This may make an HTTP request if the object is not cached.
]=]
function PermissionOverwrite:getObject()
	local guild = self._parent._parent
	if self._type == 'role' then
		return guild:getRole(self._id)
	elseif self._type == 'member' then
		return guild:getMember(self._id)
	end
end

local function getPermissions(self)
	return Permissions(self._allow_new or self._allow), Permissions(self._deny_new or self._deny)
end

local function setPermissions(self, allow, deny)
	local data, err = self.client._api:editChannelPermissions(self._parent._id, self._id, {
		allow = allow, deny = deny, type = self._type
	})
	if data then
		self._allow, self._deny = allow, deny
		return true
	else
		return false, err
	end
end

--[=[
@m getAllowedPermissions
@t mem
@r Permissions
@d Returns a permissions object that represents the permissions that this overwrite
explicitly allows.
]=]
function PermissionOverwrite:getAllowedPermissions()
	return Permissions(self._allow_new or self._allow)
end

--[=[
@m getDeniedPermissions
@t mem
@r Permissions
@d Returns a permissions object that represents the permissions that this overwrite
explicitly denies.
]=]
function PermissionOverwrite:getDeniedPermissions()
	return Permissions(self._deny_new or self._deny)
end

--[=[
@m setPermissions
@t http
@p allowed Permissions-Resolvables
@p denied Permissions-Resolvables
@r boolean
@d Sets the permissions that this overwrite explicitly allows and denies. This
method does NOT resolve conflicts. Please be sure to use the correct parameters.
]=]
function PermissionOverwrite:setPermissions(allowed, denied)
	local allow = Resolver.permissions(allowed)
	local deny = Resolver.permissions(denied)
	return setPermissions(self, allow, deny)
end

--[=[
@m setAllowedPermissions
@t http
@p allowed Permissions-Resolvables
@r boolean
@d Sets the permissions that this overwrite explicitly allows.
]=]
function PermissionOverwrite:setAllowedPermissions(allowed)
	local allow = Permissions(Resolver.permissions(allowed))
	local deny = allow:complement(self:getDeniedPermissions()) -- un-deny the allowed permissions
	return setPermissions(self, allow.value, deny.value)
end

--[=[
@m setDeniedPermissions
@t http
@p denied Permissions-Resolvables
@r boolean
@d Sets the permissions that this overwrite explicitly denies.
]=]
function PermissionOverwrite:setDeniedPermissions(denied)
	local deny = Permissions(Resolver.permissions(denied))
	local allow = deny:complement(self:getAllowedPermissions()) -- un-allow the denied permissions
	return setPermissions(self, allow.value, deny.value)
end

--[=[
@m allowPermissions
@t http
@p ... Permission-Resolvables
@r boolean
@d Allows individual permissions in this overwrite.
]=]
function PermissionOverwrite:allowPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed.value, denied.value)
end

--[=[
@m denyPermissions
@t http
@p ... Permission-Resolvables
@r boolean
@d Denies individual permissions in this overwrite.
]=]
function PermissionOverwrite:denyPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed.value, denied.value)
end

--[=[
@m clearPermissions
@t http
@p ... Permission-Resolvables
@r boolean
@d Clears individual permissions in this overwrite.
]=]
function PermissionOverwrite:clearPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed.value, denied.value)
end

--[=[
@m allowAllPermissions
@t http
@r boolean
@d Allows all permissions in this overwrite.
]=]
function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed.value, denied.value)
end

--[=[
@m denyAllPermissions
@t http
@r boolean
@d Denies all permissions in this overwrite.
]=]
function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed.value, denied.value)
end

--[=[
@m clearAllPermissions
@t http
@r boolean
@d Clears all permissions in this overwrite.
]=]
function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed.value, denied.value)
end

--[=[@p type string The overwrite type; either "role" or "member".]=]
function get.type(self)
	if type(self._type) == 'string' then
		return self._type
	elseif self._type == 1 then
		return 'member'
	else -- 0
		return 'role'
	end
end

--[=[@p channel GuildChannel The channel in which this overwrite exists.]=]
function get.channel(self)
	return self._parent
end

--[=[@p guild Guild The guild in which this overwrite exists. Equivalent to `PermissionOverwrite.channel.guild`.]=]
function get.guild(self)
	return self._parent._parent
end

--[=[@p allowedPermissions number The number representing the total permissions allowed by this overwrite.]=]
function get.allowedPermissions(self)
	return tonumber(self._allow_new) or tonumber(self._allow)
end

--[=[@p deniedPermissions number The number representing the total permissions denied by this overwrite.]=]
function get.deniedPermissions(self)
	return tonumber(self._deny_new) or tonumber(self._deny)
end

return PermissionOverwrite
