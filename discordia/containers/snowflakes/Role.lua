local Snowflake = require('../Snowflake')
local Color = require('../../utils/Color')
local Permissions = require('../../utils/Permissions')

local format = string.format

local Role, accessors = class('Role', Snowflake)

accessors.guild = function(self) return self.parent end

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

function Role:_update(data)
	self.name = data.name
	self.hoist = data.hoist
	self.managed = data.managed
	self.mentionable = data.mentionable
	self.color = data.color
	self.permissions = data.permissions
end

function Role:getColor()
	return Color(self.color)
end

function Role:getPermissions()
	return Permissions(self.permissions)
end

function Role:getMentionString()
	return format('<@&%s>', self.id)
end

function Role:setName(name)
	local success, data = self.client.api:modifyGuildRole(self.parent.id, self.id, {name = name})
	if success then self.name = data.name end
	return success
end

function Role:setHoist(hoist)
	local success, data = self.client.api:modifyGuildRole(self.parent.id, self.id, {hoist = hoist})
	if success then self.hoist = data.hoist end
	return success
end

function Role:setMentionable(mentionable)
	local success, data = self.client.api:modifyGuildRole(self.parent.id, self.id, {mentionable = mentionable})
	if success then self.mentionable = data.mentionable end
	return success
end

function Role:setColor(color)
	local success, data = self.client.api:modifyGuildRole(self.parent.id, self.id, {color = color.value})
	if success then self.color = data.color end
	return success
end

function Role:setPermissions(permissions)
	local success, data = self.client.api:modifyGuildRole(self.parent.id, self.id, {permissions = permissions.value})
	if success then self.permissions = data.permissions end
	return success
end

function Role:enablePermission(flag)
	local permissions = self:getPermissions()
	permissions:enable(flag)
	return self:setPermissions(permissions)
end

function Role:disablePermission(flag)
	local permissions = self:getPermissions()
	permissions:disable(flag)
	return self:setPermissions(permissions)
end

function Role:enableAllPermissions()
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

function Role:disableAllPermissions()
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

function Role:delete()
	local success, data = self.client.api:deleteGuildRole(self.parent.id, self.id)
	return success
end

return Role
