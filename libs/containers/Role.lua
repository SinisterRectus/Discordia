local json = require('json')

local Snowflake = require('containers/abstract/Snowflake')

local Color = require('utils/Color')
local Permissions = require('utils/Permissions')
local Resolver = require('client/Resolver')

local format = string.format

local Role = require('class')('Role', Snowflake)
local get = Role.__getters

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Role:__tostring()
	return format('%s: %s', self.__name, self._name)
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

function Role:setHoisted(hoist)
	return self:_modify({hoist = hoist or json.null})
end

function Role:setMentionable(mentionable)
	return self:_modify({mentionable = mentionable or json.null})
end

function Role:getColor()
	return Color(self._color)
end

function Role:getPermissions()
	return Permissions(self._permissions)
end

function get.hoisted(self)
	return self._hoist
end

function get.mentionable(self)
	return self._mentionable
end

function get.managed(self)
	return self._managed
end

function get.name(self)
	return self._name
end

function get.position(self)
	return self._position
end

function get.color(self)
	return self._color
end

function get.permissions(self)
	return self._permissions
end

function get.mentionString(self)
	return format('<@&%s>', self._id)
end

function get.guild(self)
	return self._parent
end

return Role
