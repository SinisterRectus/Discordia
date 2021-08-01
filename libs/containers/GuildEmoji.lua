local Snowflake = require('./Snowflake')

local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')
local json = require('json')

local checkSnowflake = typing.checkSnowflake
local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize
local readOnly = helpers.readOnly
local format = string.format

local GuildEmoji, get = class('GuildEmoji', Snowflake)

function GuildEmoji:__init(data, client)
	Snowflake.__init(self, data, client)
	self._roles = data.roles
	self._user = data.user and self.client.state:newUser(data.user) or nil -- only available via HTTP
end

function GuildEmoji:modify(payload)
	return self.client:modifyGuildEmoji(self.guildId, self.id, payload)
end

function GuildEmoji:setName(name)
	return self.client:modifyGuildEmoji(self.guildId, self.id, {name = name or json.null})
end

function GuildEmoji:setRoles(roleIds)
	return self.client:modifyGuildEmoji(self.guildId, self.id, {roleIds = roleIds or json.null})
end

function GuildEmoji:delete()
	return self.client:deleteGuildEmoji(self.guildId, self.id)
end

function GuildEmoji:getURL(ext, size)
	ext = ext and checkImageExtension(ext)
	size = size and checkImageSize(size)
	return self.client.cdn:getCustomEmojiURL(self.id, ext, size)
end

function GuildEmoji:getGuild()
	return self.client:getGuild(self.guildId)
end

function GuildEmoji:hasRole(roleId)
	roleId = checkSnowflake(roleId)
	for _, v in pairs(self.roleIds) do
		if v == roleId then
			return true
		end
	end
	return false
end

local function makeRoleFilter(ids)
	local filter = {}
	for _, id in pairs(ids) do
		filter[id] = true
	end
	return function(role)
		return filter[role.id]
	end
end

function GuildEmoji:getRoles()
	local roles, err = self.client:getGuildRoles(self.guildId)
	if roles then
		return roles:filter(makeRoleFilter(self.roleIds))
	else
		return nil, err
	end
end

function GuildEmoji:toMention()
	local fmt = self.animated and '<a:%s:%s>' or '<:%s:%s>'
	return format(fmt, self.name, self.id)
end

function get:name()
	return self._name
end

function get:guildId()
	return self._guild_id
end

function get:managed()
	return self._managed or false
end

function get:requireColons()
	return self._require_colons or false
end

function get:hash()
	return self.name .. ':' .. self.id
end

function get:animated()
	return self._animated or false
end

function get:available()
	return self._available or false
end

function get:roleIds()
	return readOnly(self._roles)
end

return GuildEmoji
