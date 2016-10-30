local bit = require('bit')
local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor

local PermissionOverwrite, accessors = class('PermissionOverwrite', Snowflake)

accessors.channel = function(self) return self.parent end
accessors.guild = function(self) return self.parent.guild end

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.type = data.type
	self:_update(data)
end

function PermissionOverwrite:_update(data)
	self.allow = data.allow
	self.deny = data.deny
end

function PermissionOverwrite:getPermissions()
	return Permissions(self.allow), Permissions(self.deny)
end

function PermissionOverwrite:getAllowedPermissions()
	return Permissions(self.allow)
end

function PermissionOverwrite:getDeniedPermissions()
	return Permissions(self.deny)
end

local function setPermissions(overwrite, allow, deny)
	local success, data = overwrite.client.api:editChannelPermissions(overwrite.parent.id, overwrite.id, {
		allow = allow, deny = deny,
	})
	if success then overwrite.allow, overwrite.deny = allow, deny end
	return success
end

function PermissionOverwrite:setAllowedPermissions(allowed)
	local allow = allowed.value
	local deny = band(bnot(allow), self.deny)
	return setPermissions(self, allow, deny)
end

function PermissionOverwrite:setDeniedPermissions(denied)
	local deny = denied.value
	local allow = band(bnot(deny), self.allow)
	return setPermissions(self, allow, deny)
end

function PermissionOverwrite:allowPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:enable(...); denied:disable(...)
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:denyPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:enable(...)
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:clearPermission(...)
	local allowed, denied = self:getPermissions()
	allowed:disable(...); denied:disable(...)
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:allowAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:enableAll(); denied:disableAll()
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:denyAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:enableAll()
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:clearAllPermissions()
	local allowed, denied = self:getPermissions()
	allowed:disableAll(); denied:disableAll()
	return setPermissions(self, allowed.value, denied.value)
end

function PermissionOverwrite:getAssociatedObject()
	if self.type == 'role' then
		return self.parent.guild.roles:get(self.id)
	else
		return self.parent.guild.members:get(self.id)
	end
end

function PermissionOverwrite:delete()
	local success, data = self.client.api:deleteChannelPermission(self.parent.id, self.id)
	return success
end

return PermissionOverwrite
