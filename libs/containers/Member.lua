local Container = require('./Container')
local Bitfield = require('../utils/Bitfield')

local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')
local helpers = require('../helpers')
local json = require('json')

local checkSnowflake = typing.checkSnowflake
local readOnly = helpers.readOnly
local format = string.format

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

local function makeRoleFilter(ids)
	local filter = {}
	for _, id in pairs(ids) do
		filter[id] = true
	end
	return function(role)
		return filter[role.id]
	end
end

function Member:getRoles()
	local roles, err = self.client:getGuildRoles(self.guildId)
	if roles then
		return roles:filter(makeRoleFilter(self.roleIds))
	else
		return nil, err
	end
end

function Member:getGuild()
	return self.client:getGuild(self.guildId)
end

local function positionSorter(a, b)
	if a.position == b.position then
		return tonumber(a.id) < tonumber(b.id) -- equal position; lesser id = greater role
	else
		return a.position > b.position -- greater position = greater role
	end
end

local function colorFilter(r)
	return r.color > 0
end

function Member:getHighestRole()
	local roles, err = self:getRoles()
	if roles then
		roles:sort(positionSorter)
		return roles:get(1)
	else
		return nil, err
	end
end

function Member:getColor()
	local roles, err = self:getRoles()
	if roles then
		roles = roles:filter(colorFilter)
		roles:sort(positionSorter)
		local role = roles:get(1)
		return role and role.color or 0
	else
		return nil, err
	end
end

function Member:getPermissions(channelId)

	local guild, err = self:getGuild()
	if not guild then
		return nil, err
	end

	local channel
	if channelId then
		channel, err = self.client:getChannel(checkSnowflake(channelId))
		if not channel then
			return nil, err
		end
		if self.guildId ~= channel.guildId then
			return error('member/channel mismatch: both must have the same guild', 2)
		end
	end

	if self.id == guild.ownerId then
		return Bitfield(enums.permission)
	end

	local roles = guild:getRoles()
	local everyone = roles:get(guild.id)
	local permissions = Bitfield(everyone.permissions)
	roles = roles:filter(makeRoleFilter(self.roleIds))

	for role in roles:iter() do
		permissions:enableValue(role.permissions)
	end

	if permissions:hasValue(enums.permission.administrator) then
		return Bitfield(enums.permission)
	end

	if channel then

		local overwrites = channel.permissionOverwrites

		local everyoneOverwrite = overwrites:get(guild.id)
		if everyoneOverwrite then
			permissions:disableValue(everyoneOverwrite.deniedPermissions)
			permissions:enableValue(everyoneOverwrite.allowedPermissions)
		end

		do
			local allowed, denied = Bitfield(), Bitfield()
			for role in roles:iter() do
				local roleOverwrite = overwrites:get(role.id)
				if roleOverwrite then
					allowed:enableValue(roleOverwrite.allowedPermissions)
					denied:enableValue(roleOverwrite.deniedPermissions)
				end
			end
			permissions:disableValue(denied)
			permissions:enableValue(allowed)
		end

		local memberOverwrite = overwrites:get(self.id)
		if memberOverwrite then
			permissions:disableValue(memberOverwrite.deniedPermissions)
			permissions:enableValue(memberOverwrite.allowedPermissions)
		end

	end

	return permissions

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

function Member:kick(reason)
	return self.client:removeGuildMember(self.guildId, self.user.id, reason)
end

function Member:ban(reason, days)
	return self.client:createGuildBan(self.guildId, self.user.id, reason, days)
end

function Member:unban(reason)
	return self.client:removeGuildBan(self.guildId, self.user.id, reason)
end

function Member:toMention()
	return format('<@%s>', self.user.id)
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
