local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')

local class = require('../class')
local typing = require('../typing')
local enums = require('../enums')
local json = require('json')

local checkType, checkInteger = typing.checkType, typing.checkInteger
local checkEnum = typing.checkEnum
local format = string.format

local Role, get = class('Role', Snowflake)

function Role:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = assert(data.guild_id)
	return self:_load(data)
end

function Role:_load(data)
	self._name = data.name
	self._color = data.color
	self._hoist = data.hoist
	self._position = data.position
	self._permissions = data.permissions_new
	self._managed = data.managed
	self._mentionable = data.mentionable
end

function Role:_modify(payload)
	local data, err = self.client.api:modifyGuildRole(self.guildId, self.id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Role:delete()
	local data, err = self.client.api:deleteGuildRole(self.guildId, self.id)
	if data then
		return true
	else
		return false, err
	end
end

-- TODO: sorting

function Role:getGuild()
	return self.client:getGuild(self.guildId)
end

function Role:setName(name)
	return self:_modify {name = name and checkType('string', name) or json.null}
end

function Role:setColor(color)
	return self:_modify {color = color and checkInteger(color) or json.null}
end

function Role:setPermissions(permissions)
	return self:_modify {permissions = permissions and checkInteger(permissions) or json.null}
end

function Role:enablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		local permission = select(i, ...)
		permissions:enableValue(checkEnum(enums.permission, permission))
	end
	return self:setPermissions(permissions.value)
end

function Role:disablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		local permission = select(i, ...)
		permissions:disableValue(checkEnum(enums.permission, permission))
	end
	return self:setPermissions(permissions.value)
end

function Role:hoist()
	return self:_modify {hoist = true}
end

function Role:unhoist()
	return self:_modify {hoist = false}
end

function Role:enableMentioning()
	return self:_modify {mentionable = true}
end

function Role:disableMentioning()
	return self:_modify {mentionable = false}
end

function get:hoisted()
	return self._hoist
end

function get:mentionable()
	return self._mentionable
end

function get:managed()
	return self._managed
end

function get:name()
	return self._name
end

function get:position()
	return self._position
end

function get:color()
	return self._color
end

function get:permissions()
	return self._permissions
end

function get:mentionString()
	return format('<@&%s>', self.id)
end

function get:guildId()
	return self._guild_id
end

return Role
