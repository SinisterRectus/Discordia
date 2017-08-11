local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local band, bnot = bit.band, bit.bnot

local PermissionOverwrite, get = require('class')('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

--[[
@method delete
@ret boolean
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
@ret Role|Member
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
]]
function PermissionOverwrite:getAllowedPermissions()
	return Permissions(self._allow)
end

--[[
@method getDeniedPermissions
@ret Permissions
]]
function PermissionOverwrite:getDeniedPermissions()
	return Permissions(self._deny)
end

--[[
@method setAllowedPermissions
@param allowed: Permissions Resolveable
@ret boolean
]]
function PermissionOverwrite:setAllowedPermissions(allowed)
	local allow = Resolver.permissions(allowed)
	local deny = band(bnot(allow), self._deny) -- un-deny the allowed permissions
	return setPermissions(self, allow, deny)
end

--[[
@method setDeniedPermissions
@param denied: Permissions Resolveable
@ret boolean
]]
function PermissionOverwrite:setDeniedPermissions(denied)
	local deny = Resolver.permissions(denied)
	local allow = band(bnot(deny), self._allow) -- un-allow the denied permissions
	return setPermissions(self, allow, deny)
end

--[[
@method allowPermissions
@param ...: Permissions Resolveable(s)
@ret boolean
]]
function PermissionOverwrite:allowPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method denyPermissions
@param ...: Permissions Resolveable(s)
@ret boolean
]]
function PermissionOverwrite:denyPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method clearPermissions
@param ...: Permissions Resolveable(s)
@ret boolean
]]
function PermissionOverwrite:clearPermissions(...)
	local allowed, denied = getPermissions(self)
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method allowAllPermissions
@ret boolean
]]
function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method denyAllPermissions
@ret boolean
]]
function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@method clearAllPermissions
@ret boolean
]]
function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = getPermissions(self)
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed._value, denied._value)
end

--[[
@property type: string
]]
function get.type(self)
	return self._type
end

--[[
@property channel: GuildChannel
]]
function get.channel(self)
	return self._parent
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent._parent
end

--[[
@property allowedPermissions: number
]]
function get.allowedPermissions(self)
	return self._allow
end

--[[
@property deniedPermissions: number
]]
function get.deniedPermissions(self)
	return self._deny
end

return PermissionOverwrite
