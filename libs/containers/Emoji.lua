local Snowflake = require('./Snowflake')
local Role = require('./Role')
local User = require('./User')

local class = require('../class')
local typing = require('../typing')
local json = require('json')
local constants = require('../constants')

local CDN_URL = constants.CDN_URL
local checkType = typing.checkType
local checkSnowflake = typing.checkSnowflake
local format = string.format
local insert = table.insert

local Emoji, get = class('Emoji', Snowflake)

function Emoji:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = assert(data.guild_id)
	return self:_load(data)
end

function Emoji:_load(data)
	self._name = data.name
	self._require_colons = data.require_colons
	self._managed = data.managed
	self._animated = data.animated
	self._available = data.available
	self._roles = data.roles
	self._user = data.user and User(data.user, self.client) or nil -- only availble via HTTP
end

function Emoji:_modify(payload)
	local data, err = self.client.api:modifyGuildEmoji(self.guildId, self.id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Emoji:setName(name)
	return self:_modify({name = name and checkType('string', name) or json.null})
end

function Emoji:setRoles(roles)
	for i, v in ipairs(checkType('table', roles)) do
		roles[i] = checkSnowflake(v)
	end
	return self:_modify({roles = roles or json.null})
end

function Emoji:delete()
	local data, err = self.client.api:deleteGuildEmoji(self.guildId, self.id)
	if data then
		return true
	else
		return false, err
	end
end

function Emoji:getGuild()
	return self.client:getGuild(self.guildId)
end

function Emoji:hasRole(roleId)
	roleId = checkSnowflake(roleId)
	for _, v in ipairs(self.roleIds) do
		if v == roleId then
			return true
		end
	end
	return false
end

function Emoji:getRoles()
	local roles = {}
	if #self.roleIds == 0 then
		return roles
	end
	local filter = {}
	for _, id in ipairs(self.roleIds) do
		filter[id] = true
	end
	local data, err = self.client.api:getGuildRoles(self.guildId)
	if data then
		for _, v in ipairs(data) do
			if filter[v.id] then
				v.guild_id = self.guildId
				insert(roles, Role(v, self.client))
			end
		end
		return roles
	else
		return nil, err
	end
end

function get:name()
	return self._name
end

function get:guildId()
	return self._guild_id
end

function get:mentionString()
	local fmt = self.animated and '<a:%s:%s>' or '<:%s:%s>'
	return format(fmt, self.name, self.id)
end

function get:url()
	local ext = self.animated and 'gif' or 'png'
	return format('%s/emojis/%s.%s', CDN_URL, self.id, ext)
end

function get:managed()
	return not not self._managed
end

function get:requireColons()
	return not not self._require_colons
end

function get:hash()
	return self.name .. ':' .. self.id
end

function get:animated()
	return not not self._animated
end

function get:roleIds()
	return self._roles or {}
end

return Emoji
