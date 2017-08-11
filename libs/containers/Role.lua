local json = require('json')

local Snowflake = require('containers/abstract/Snowflake')

local Color = require('utils/Color')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local format = string.format

local Role, get = require('class')('Role', Snowflake)

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Role:_modify(payload)
	local data, err = self.client._api:modifyGuildRole(self._parent._id, self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Role:delete()
	local data, err = self.client._api:deleteGuildRole(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

function Role:setPosition(position)
	return self:_modify({position = position or json.null})
end

function Role:setColor(color)
	color = color and Resolver.color(color)
	return self:_modify({color = color or json.null})
end

function Role:setPermissions(permissions)
	permissions = permissions and Resolver.permissions(permissions)
	return self:_modify({permissions = permissions or json.null})
end

function Role:hoist()
	return self:_modify({hoist = true})
end

function Role:unhoist()
	return self:_modify({hoist = false})
end

function Role:enableMentioning()
	return self:_modify({mentionable = true})
end

function Role:disableMentioning()
	return self:_modify({mentionable = false})
end

function Role:enablePermissions(...)
	local permissions = self:getPermissions()
	permissions:enable(...)
	return self:setPermissions(permissions)
end

function Role:disablePermissions(...)
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

function Role:getColor()
	return Color(self._color)
end

function Role:getPermissions()
	return Permissions(self._permissions)
end

--[[
@property hoisted: boolean
]]
function get.hoisted(self)
	return self._hoist
end

--[[
@property mentionable: boolean
]]
function get.mentionable(self)
	return self._mentionable
end

--[[
@property managed: boolean
]]
function get.managed(self)
	return self._managed
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property position: number
]]
function get.position(self)
	return self._position
end

--[[
@property color: number
]]
function get.color(self)
	return self._color
end

--[[
@property permissions: number
]]
function get.permissions(self)
	return self._permissions
end

--[[
@property mentionString: string
]]
function get.mentionString(self)
	return format('<@&%s>', self._id)
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent
end

return Role
