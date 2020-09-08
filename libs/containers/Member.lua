local Container = require('./Container')
local User = require('./User')

local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')
local json = require('json')

local checkSnowflake = typing.checkSnowflake
local insert, sort = table.insert, table.sort
local readOnly = helpers.readOnly

local Member, get = class('Member', Container)

function Member:__init(data, client)
	Container.__init(self, client)
	self._guild_id = assert(data.guild_id)
	self._user = User(data.user, client)
	self._nick = data.nick
	self._roles = data.roles
	self._joined_at = data.joined_at
	self._premium_since = data.premium_since
	self._deaf = data.deaf
	self._mute = data.mute
end

function Member:__eq(other)
	return self.guildId == other.guildId and self.user.id == other.user.id
end

function Member:getRoles()
	local filtered = {}
	if #self.roleIds == 0 then
		return filtered
	end
	local filter = {}
	for _, id in ipairs(self.roleIds) do
		filter[id] = true
	end
	local roles, err = self.client:getGuildRoles(self.guildId)
	if roles then
		for _, role in pairs(roles) do
			if filter[role.id] then
				insert(filtered, role)
			end
		end
		return filtered
	else
		return nil, err
	end
end

function Member:getGuild()
	return self.client:getGuild(self.guildId)
end

local function sorter(a, b)
	if a.position == b.position then
		return tonumber(a.id) < tonumber(b.id) -- equal position; lesser id = greater role
	else
		return a.position > b.position -- greater position = greater role
	end
end

function Member:getHighestRole()
	local roles = self:getRoles()
	local sorted = {}
	for _, role in pairs(roles) do
		insert(sorted, role)
	end
	sort(sorted, sorter)
	return sorted[1]
end

function Member:getColor()
	local roles = self:getRoles()
	local sorted = {}
	for _, role in pairs(roles) do
		if role.color > 0 then
			insert(sorted, role)
		end
	end
	sort(sorted, sorter)
	return sorted[1] and sorted[1].color or 0
end

-- TODO: permissions

local function has(arr, value)
	for _, v in ipairs(arr) do
		if v == value then
			return true
		end
	end
	return false
end

function Member:addRole(roleId)
	return self.client:addGuildMemberRole(self.guildId, self.user.id, roleId)
end

function Member:removeRole(roleId)
	return self.client:removeGuildMemberRole(self.guildId, self.user.id, roleId)
end

function Member:hasRole(roleId)
	roleId = checkSnowflake(roleId)
	if roleId == self.guildId then
		return true
	end
	return has(self._roles, roleId)
end

function Member:setNickname(nick)
	return self.client:modifyGuildMember(self.guildId, self.user.id, {nick = nick or json.null})
end

function Member:setVoiceChannel(channelId)
	return self.client:modifyGuildMember(self.guildId, self.user.id, {channel_id = channelId or json.null})
end

function Member:mute()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {mute = true})
end

function Member:unmute()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {mute = false})
end

function Member:deafen()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {deaf = true})
end

function Member:undeafen()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {deaf = false})
end

function get:name()
	return self.nickname or self.user.username
end

function get:nickname()
	return self._nick
end

function get:joinedAt()
	return self._joined_at
end

function get:premiumSince()
	return self._premium_since
end

function get:muted()
	return self._muted
end

function get:deafened()
	return self._deaf
end

function get:guildId()
	return self._guild_id
end

function get:roleIds()
	return readOnly(self._roles)
end

return Member
