local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local band, bnot = bit.band, bit.bnot

local PermissionOverwrite, get = require('class')('PermissionOverwrite', Snowflake)

--[[
@class PermissionOverwrite x Snowflake

Represents an object that is used to allow or deny specific permissions for a
role or member in a Discord guild channel.
]]
function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

--[[
@method delete
@tags http
@ret boolean

Delets the permission overwrite. This can be undone by created a new version of
the same overwrite.
]]
function PermissionOverwrite:delete()
	local data, err = self.client._api:deleteChannelPermission(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method getObject
@tags http
@ret Role|Member

Returns the object associated with this overwrite, either a role or member.
This may make an HTTP request if the object is not cached.
]]
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

--[[
@method getAllowedPermissions
@ret Permissions

Returns a permissions object that represents the permissions that this overwrite
explicitly allows.
]]
function PermissionOverwrite:getAllowedPermissions()
	return Permissions(self._allow)
end

--[[
@method getDeniedPermissions
@ret Permissions

Returns a permissions object that represents the permissions that this overwrite
explicitly denies.
]]
function PermissionOverwrite:getDeniedPermissions()
	return Permissions(self._deny)
end

--[[
@method setAllowedPermissions
@tags http
@param allowed: Permissions Resolveable
@ret boolean

Sets the permissions that this overwrite explicitly allows.
]]
function PermissionOverwrite:setAllowedPermissions(allowed)
	local allow = Resolver.permissions(allowed)
	local deny = band(bnot(allow), self._deny) -- un-deny the allowed permissions
	return setPermissions(self, allow, deny)
end

--[[
@method setDeniedPermissions
@tags http
@param denied: Permissions Resolveable
@ret boolean

Sets the permissions that this overwrite explicitly denies.
]]
function PermissionOverwrite:setDeniedPermissions(denied)
	local deny = Resolver.permissions(denied)
	local allow = band(bnot(deny), self._allow) -- un-allow the denied permissions
	return setPermissions(self, allow, deny)
end

--[[
@method allowPermissions
@tags http
@param ...: Permissions Resolveable(s)
@ret boolean

Allows individual permissions in this overwrite.
]]
function PermissionOverwrite:allowPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method denyPermissions
@tags http
@param ...: Permissions Resolveable(s)
@ret boolean

Denies individual permissions in this overwrite.
]]
function PermissionOverwrite:denyPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method clearPermissions
@tags http
@param ...: Permissions Resolveable(s)
@ret boolean

Clears individual permissions in this overwrite.
]]
function PermissionOverwrite:clearPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method allowAllPermissions
@tags http
@ret boolean

Allows all permissions in this overwrite.
]]
function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method denyAllPermissions
@tags http
@ret boolean

Denies all permissions in this overwrite.
]]
function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method clearAllPermissions
@tags http
@ret boolean

Clears all permissions in this overwrite.
]]
function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@property type: string

The overwrite type; either "role" or "member".
]]
function get.type(self)
	return self._type
end

--[[
@property channel: GuildChannel

The channel in which this overwrite exists. Equivalent to `$.parent`.
]]
function get.channel(self)
	return self._parent
end

--[[
@property guild: Guild

The guild in which this overwrite exists. Equivalent to `$.channel.guild`.
]]
function get.guild(self)
	return self._parent._parent
end

--[[
@property allowedPermissions: number

The number representing the total permissions allowed by this overwrite.
]]
function get.allowedPermissions(self)
	return self._allow
end

--[[
@property deniedPermissions: number

The number representing the total permissions denied by this overwrite.
]]
function get.deniedPermissions(self)
	return self._deny
end

return PermissionOverwrite
