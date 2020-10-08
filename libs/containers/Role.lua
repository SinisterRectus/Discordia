local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')

local class = require('../class')
local typing = require('../typing')
local enums = require('../enums')
local json = require('json')

local checkEnum = typing.checkEnum
local format = string.format

local Role, get = class('Role', Snowflake)

function Role:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = assert(data.guild_id)
	self._name = data.name
	self._color = data.color
	self._hoist = data.hoist
	self._position = data.position
	self._permissions = data.permissions_new
	self._managed = data.managed
	self._mentionable = data.mentionable
end

function Role:delete()
	return self.client:deleteGuildRole(self.guildId, self.id)
end

function Role:getGuild()
	return self.client:getGuild(self.guildId)
end

function Role:setName(name)
	return self.client:modifyGuildRole(self.guildId, self.id, {name = name or json.null})
end

function Role:setColor(color)
	return self.client:modifyGuildRole(self.guildId, self.id, {color = color or json.null})
end

function Role:setPermissions(permissions)
	return self.client:modifyGuildRole(self.guildId, self.id, {permissions = permissions or json.null})
end

function Role:enablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		permissions:enableValue(checkEnum(enums.permission, select(i, ...)))
	end
	return self:setPermissions(permissions)
end

function Role:disablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		permissions:disableValue(checkEnum(enums.permission, select(i, ...)))
	end
	return self:setPermissions(permissions)
end

function Role:hoist()
	return self.client:modifyGuildRole(self.guildId, self.id, {hoisted = true})
end

function Role:unhoist()
	return self.client:modifyGuildRole(self.guildId, self.id, {hoisted = false})
end

function Role:enableMentioning()
	return self.client:modifyGuildRole(self.guildId, self.id, {mentionable = true})
end

function Role:disableMentioning()
	return self.client:modifyGuildRole(self.guildId, self.id, {mentionable = false})
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
