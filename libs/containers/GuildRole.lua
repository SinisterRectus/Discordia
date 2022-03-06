local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')

local class = require('../class')
local typing = require('../typing')
local enums = require('../enums')
local json = require('json')

local checkEnum = typing.checkEnum
local format = string.format

local GuildRole, get = class('GuildRole', Snowflake)

function GuildRole:__init(data, client)
	Snowflake.__init(self, data, client)
end

function GuildRole:delete()
	return self.client:deleteGuildRole(self.guildId, self.id)
end

function GuildRole:getGuild()
	return self.client:getGuild(self.guildId)
end

function GuildRole:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Role has no icon'
	end
	return self.client.cdn:getRoleIconURL(self.id, self.icon, ext, size)
end

function GuildRole:modify(payload)
	return self.client:modifyGuildRole(self.guildId, self.id, payload)
end

function GuildRole:setName(name)
	return self.client:modifyGuildRole(self.guildId, self.id, {name = name or json.null})
end

function GuildRole:setColor(color)
	return self.client:modifyGuildRole(self.guildId, self.id, {color = color or json.null})
end

function GuildRole:setPermissions(permissions)
	return self.client:modifyGuildRole(self.guildId, self.id, {permissions = permissions or json.null})
end

function GuildRole:enablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		permissions:enableValue(checkEnum(enums.permission, select(i, ...)))
	end
	return self:setPermissions(permissions)
end

function GuildRole:disablePermissions(...)
	local permissions = Bitfield(self.permissions)
	for i = 1, select('#', ...) do
		permissions:disableValue(checkEnum(enums.permission, select(i, ...)))
	end
	return self:setPermissions(permissions)
end

function GuildRole:hoist()
	return self.client:modifyGuildRole(self.guildId, self.id, {hoisted = true})
end

function GuildRole:unhoist()
	return self.client:modifyGuildRole(self.guildId, self.id, {hoisted = false})
end

function GuildRole:enableMentioning()
	return self.client:modifyGuildRole(self.guildId, self.id, {mentionable = true})
end

function GuildRole:disableMentioning()
	return self.client:modifyGuildRole(self.guildId, self.id, {mentionable = false})
end

function GuildRole:toMention()
	return format('<@&%s>', self.id)
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

function get:icon()
	return self._icon
end

function get:emoji()
	return self._unicode_emoji
end

function get:permissions()
	return self._permissions
end

function get:guildId()
	return self._guild_id
end

return GuildRole
