local Snowflake = require('containers/abstract/Snowflake')

local Color = require('utils/Color')
local Permissions = require('utils/Permissions')

local format = string.format

local Role = require('class')('Role', Snowflake)
local get = Role.__getters

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Role:__tostring()
	return format('%s: %s', self.__name, self._name)
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
	return Color(self._color)
end

function get.permissions(self)
	return Permissions(self._permissions)
end

function get.mentionString(self)
	return format('<@&%s>', self._id)
end

function get.guild(self)
	return self._parent
end

return Role
