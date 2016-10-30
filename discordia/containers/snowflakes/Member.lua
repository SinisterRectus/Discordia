local Snowflake = require('../Snowflake')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Member, accessors = class('Member', Snowflake)
Member.status = 'offline'

accessors.name = function(self) return self.nick or self.user.username end
accessors.guild = function(self) return self.parent end
accessors.nickname = function(self) return self.nick end

accessors.id = function(self) return self.user.id end
accessors.bot = function(self) return self.user.bot end
accessors.avatar = function(self) return self.user.avatar end
accessors.username = function(self) return self.user.username end
accessors.discriminator = function(self) return self.user.discriminator end

function Member:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.deaf = data.deaf
	self.mute = data.mute
	self.joinedAt = data.joined_at
	self.user = self.client.users:get(data.user.id) or self.client.users:new(data.user)
	self:_update(data)
end

function Member:__tostring()
	if self.nick then
		return format('%s: %s (%s)', self.__name, self.user.username, self.nick)
	else
		return format('%s: %s', self.__name, self.user.username)
	end
end

function Member:_update(data)
	self.nick = data.nick
	self.roles = data.roles -- raw table of IDs
end

function Member:_createPresence(data)
	self.status = data.status
	if self.game and data.game then
		for k, v in pairs(self.game) do
			self.game[k] = data.game[k]
		end
	else
		self.game = data.game
	end
end

function Member:_updatePresence(data)
	self:_createPresence(data)
	self.user:_update(data.user)
end

-- User-compatability methods --

function Member:getMembership(guild)
	return self.user:getMembership(guild or self.guild)
end

function Member:sendMessage(...)
	return self.user:sendMessage(...)
end

function Member:getAvatarUrl()
	return self.user:getAvatarUrl()
end

function Member:getMentionString()
	return self.user:getMentionString()
end

function Member:ban(guild, messageDeleteDays)
	if not messageDeleteDays and type(guild) == 'number' then
		messageDeleteDays, guild = guild, self.guild
	end
	return self.user:ban(guild or self.guild, messageDeleteDays)
end

function Member:unban(guild)
	return self.user:unban(guild or self.guild)
end

function Member:kick(guild)
	return self.user:kick(guild or self.guild)
end

-- Member-specific methods --

local function applyRoles(member, roles)
	local success = member.client.api:modifyGuildMember(member.parent.id, member.user.id, {roles = roles})
	if success then member.roles = roles end
	return success
end

local function mapRoles(roles, map, tbl)
	if roles.iter then
		for role in roles:iter() do
			map(role, tbl)
		end
	else
		for _, role in pairs(roles) do
			map(role, tbl)
		end
	end
	return tbl
end

function Member:setRoles(roles)
	local map = function(role, tbl)
		insert(tbl, role.id)
	end
	local roleIds = mapRoles(roles, map, {})
	return applyRoles(self, roleIds)
end

function Member:addRoles(roles)
	local map = function(role, tbl)
		insert(tbl, role.id)
	end
	local roleIds = mapRoles(roles, map, self.roles)
	return applyRoles(self, roleIds)
end

function Member:removeRoles(roles)
	local map = function(role, tbl)
		tbl[role.id] = true
	end
	local removals = mapRoles(roles, map, {})
	local roleIds = {}
	for _, id in ipairs(self.roles) do
		if not removals[id] then
			insert(roleIds, id)
		end
	end
	return applyRoles(self, roleIds)
end

function Member:addRole(role)
	local roleIds = {role.id}
	for _, id in ipairs(self.roles) do
		insert(roleIds, id)
	end
	return applyRoles(self, roleIds)
end

function Member:removeRole(role)
	local roleIds = {}
	for _, id in ipairs(self.roles) do
		if id ~= role.id then
			insert(roleIds, id)
		end
	end
	return applyRoles(self, roleIds)
end

function Member:setNickname(nickname)
	if self.user.id == self.client.user.id then
		return self.client:setNickname(self.parent, nickname)
	end
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {nick = nickname or ''})
	if success then self.nick = nickname ~= '' and nickname or nil end
	return success
end

function Member:setMute(mute)
	mute = mute or false
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {mute = mute})
	if success then self.mute = mute end
	return success
end

function Member:setDeaf(deaf)
	deaf = deaf or false
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {deaf = deaf})
	if success then self.deaf = deaf end
	return success
end

function Member:setVoiceChannel(channel)
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {channel_id = channel.id})
	return success
end

function Member:getRoles()
	local roles = self.guild.roles
	return wrap(function()
		for _, id in ipairs(self.roles) do
			yield(roles:get(id))
		end
	end)
end

Member.setNick = Member.setNickname

return Member
