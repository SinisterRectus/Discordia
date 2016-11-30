local Snowflake = require('../Snowflake')
local Color = require('../../utils/Color')
local Permissions = require('../../utils/Permissions')

local format = string.format

local Role, property, method = class('Role', Snowflake)
Role.__description = "Represents a Discord guild role."

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Role:__tostring()
	return format('%s: %s', self.__name, self._name)
end

local function getColor(self)
	return Color(self._color)
end

local function getPermissions(self)
	return Permissions(self._permissions)
end

local function setName(self, name)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {name = name})
	if success then self._name = data.name end
	return success
end

local function setHoist(self, hoist)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {hoist = hoist})
	if success then self._hoist = data.hoist end
	return success
end

local function setMentionable(self, mentionable)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {mentionable = mentionable})
	if success then self._mentionable = data.mentionable end
	return success
end

local function setPosition(self, position)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {position = position})
	if success then self._position = data.position end
	return success
end

local function setColor(self, color)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {color = color._value})
	if success then self._color = data.color end
	return success
end

local function setPermissions(self, permissions)
	local success, data = self._parent._parent._api:modifyGuildRole(self._parent._id, self._id, {permissions = permissions._value})
	if success then self._permissions = data.permissions end
	return success
end

local function getMentionString(self)
	return format('<@&%s>', self._id)
end

local function enablePermissions(self, ...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

local function disablePermissions(self, ...)
	local permissions = self:getPermissions()
	permissions:disable(...)
	return self:setPermissions(permissions)
end

local function enableAllPermissions(self)
	local permissions = self:getPermissions()
	permissions:enableAll()
	return self:setPermissions(permissions)
end

local function disableAllPermissions(self)
	local permissions = self:getPermissions()
	permissions:disableAll()
	return self:setPermissions(permissions)
end

local function delete(self)
	return (self._parent._parent._api:deleteGuildRole(self._parent._id, self._id))
end

property('name', '_name', setName, 'string', "Role name")
property('hoist', '_hoist', setHoist, 'boolean', "Whether members with this role are displayed separated from others")
property('guild', '_parent', nil, 'Guild', "Discord guild in which the role exists")
property('managed', '_managed', nil, 'boolean', "Whether the role is managed by an integration")
property('position', '_position', setPosition, 'number', "The position setting of the guild's list of roles")
property('mentionable', '_mentionable', setMentionable, 'boolean', "Whether guild members can mention this role")
property('color', getColor, setColor, 'Color', "Object representing the role color")
property('permissions', getPermissions, setPermissions, 'Permissions', "Object representing the role's permissions")
property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a role mention")

method('enablePermissions', enablePermissions, 'flag[, ...]', "Enables permissions for the role by flag.")
method('disablePermissions', disablePermissions, 'flag[, ...]', "Disables permissions for the role by flag.")
method('enableAllPermissions', enableAllPermissions, nil, "Enables all permissions for the role.")
method('disableAllPermissions', disableAllPermissions, nil, "Disables all permissions for the role.")
method('delete', delete, nil, "Permanently deletes the role.")

return Role
