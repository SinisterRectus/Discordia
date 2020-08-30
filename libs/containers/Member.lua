local Container = require('./Container')
local User = require('./User')
local Role = require('./Role')

local class = require('../class')
local typing = require('../typing')

local checkType, checkSnowflake = typing.checkType, typing.checkSnowflake
local insert, remove, sort = table.insert, table.remove, table.sort

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

function Member:getColor()
	local roles = self:getRoles()
	local sorted = {}
	for _, role in pairs(roles) do
		if role.color > 0 then
			insert(sorted, role)
		end
	end
	sort(sorted, roles, sorter)
	return sorted[1] and sorted[1].color or 0 -- TODO: return Color or number?
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
	roleId = checkSnowflake(roleId)
	if roleId == self.guildId then
		return nil, 'Cannot add "everyone" role'
	end
	local data, err = self.client.api:addGuildMemberRole(self.guildId, self.id, roleId)
	if data then
		if not has(self._roles, roleId) then
			insert(self._roles, roleId)
		end
		return true
	else
		return false, err
	end
end

function Member:removeRole(roleId)
	roleId = checkSnowflake(roleId)
	if roleId == self.guildId then
		return nil, 'Cannot remove "everyone" role'
	end
	local data, err = self.client.api:removeGuildMemberRole(self.guildId, self.id, roleId)
	if data then
		for i, v in ipairs(self._roles) do
			if v == roleId then
				remove(self._roles, i)
				break
			end
		end
		return true
	else
		return false, err
	end
end

function Member:hasRole(roleId)
	roleId = checkSnowflake(roleId)
	if roleId == self.guildId then
		return true
	end
	return has(self._roles, roleId)
end

function Member:setNickname(nick)
	nick = nick and checkType('string', nick) or ''
	local data, err
	if self.user.id == self.client.userId then
		data, err = self.client.api:modifyCurrentUsersNick(self.guildId, {nick = nick})
	else
		data, err = self.client.api:modifyGuildMember(self.guildId, self.id, {nick = nick})
	end
	if data then
		self._nick = nick ~= '' and nick or nil
		return true
	else
		return false, err
	end
end

function Member:setVoiceChannel(channelId)
	local data, err = self.client.api:modifyGuildMember(self.guildId, self.id, {channel_id = checkSnowflake(channelId)})
	if data then
		-- TODO: load data
		return true
	else
		return false, err
	end
end

function Member:mute()
	local data, err = self.client.api:modifyGuildMember(self._parent._id, self.id, {mute = true})
	if data then
		self._mute = true
		return true
	else
		return false, err
	end
end

function Member:unmute()
	local data, err = self.client.api:modifyGuildMember(self.guildId, self.id, {mute = false})
	if data then
		self._mute = false
		return true
	else
		return false, err
	end
end

function Member:deafen()
	local data, err = self.client.api:modifyGuildMember(self.guildId, self.id, {deaf = true})
	if data then
		self._deaf = true
		return true
	else
		return false, err
	end
end

function Member:undeafen()
	local data, err = self.client.api:modifyGuildMember(self.guildId, self.id, {deaf = false})
	if data then
		self._deaf = false
		return true
	else
		return false, err
	end
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

function get:roleIds()
	return self._roles or {}
end

return Member
