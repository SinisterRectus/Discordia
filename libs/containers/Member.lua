local Container = require('./Container')

local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')
local json = require('json')

local checkSnowflake = typing.checkSnowflake
local readOnly = helpers.readOnly

local Member, get = class('Member', Container)

function Member:__init(data, client)
	Container.__init(self, client)
	self._guild_id = assert(data.guild_id)
	self._user = client.state:newUser(data.user)
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
	local filter = {}
	for _, id in pairs(self.roleIds) do
		filter[id] = true
	end
	local roles, err = self.client:getGuildRoles(self.guildId)
	if roles then
		return roles:filter(function(r) return filter[r.id] end)
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

local function filter(r)
	return r.color > 0
end

function Member:getHighestRole()
	local roles, err = self:getRoles()
	if roles then
		roles:sort(sorter)
		return roles:get(1)
	else
		return nil, err
	end
end

function Member:getColor()
	local roles, err = self:getRoles()
	if roles then
		roles = roles:filter(filter)
		roles:sort(sorter)
		local role = roles:get(1)
		return role and role.color or 0
	else
		return nil, err
	end
end

-- TODO: permissions

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
	for _, v in pairs(self.roleIds) do
		if v == roleId then
			return true
		end
	end
	return false
end

function Member:setRoles(roleIds)
	return self.client:modifyGuildMember(self.guildId, self.user.id, {roleIds = roleIds or json.null})
end

function Member:setNickname(nickname)
	return self.client:modifyGuildMember(self.guildId, self.user.id, {nickname = nickname or json.null})
end

function Member:setVoiceChannel(channelId)
	return self.client:modifyGuildMember(self.guildId, self.user.id, {channelId = channelId or json.null})
end

function Member:mute()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {muted = true})
end

function Member:unmute()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {muted = false})
end

function Member:deafen()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {deafened = true})
end

function Member:undeafen()
	return self.client:modifyGuildMember(self.guildId, self.user.id, {deafened = false})
end

function get:id() -- user shortcut
	return self.user.id
end

function get:user()
	return self._user
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
