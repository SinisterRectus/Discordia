local Snowflake = require('../Snowflake')
local Color = require('../../utils/Color')
local Permissions = require('../../utils/Permissions')

local format = string.format

local Role, get, set = class('Role', Snowflake)

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self:_update(data)
end

get('name', '_name')
get('hoist', '_hoist')
get('guild', '_parent')
get('managed', '_managed')
get('mentionable', '_mentionable')

get('color', function(self)
	return Color(self._color)
end)

get('permissions', function(self)
	return Permissions(self._permissions)
end)

get('mentionString', function(self)
	return format('<@&%s>', self._id)
end)

set('name', function(self, name)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {name = name})
	if success then self._name = data.name end
	return success
end)

set('hoist', function(self, hoist)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {hoist = hoist})
	if success then self._hoist = data.hoist end
	return success
end)

set('mentionable', function(self, mentionable)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {mentionable = mentionable})
	if success then self._mentionable = data.mentionable end
	return success
end)

set('position', function(self, position)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {position = position})
	if success then self._position = data.position end
	return success
end)

set('color', function(self, color)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {color = color._value})
	if success then self._color = data.color end
	return success
end)

set('permissions', function(self, permissions)
	local success, data = self.client.api:modifyGuildRole(self._parent._id, self._id, {permissions = permissions._value})
	if success then self._permissions = data.permissions end
	return success
end)

function Role:enablePermission(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

function Role:disablePermission(...)
	local permissions = self:getPermissions()
	permissions:disable(...)
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
	local success, data = self.client.api:deleteGuildRole(self._parent._id, self._id)
	return success
end

return Role
