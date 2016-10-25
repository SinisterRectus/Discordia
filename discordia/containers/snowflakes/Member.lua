local Snowflake = require('../Snowflake')

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
	self.user = self.client:getUserById(data.user.id) or self.client.users:new(data.user)
	self:update(data)
end

function Member:__tostring()
	if self.nick then
		return string.format('%s: %s (%s)', self.__name, self.user.username, self.nick)
	else
		return string.format('%s: %s', self.__name, self.user.username)
	end
end

function Member:update(data)
	self.nick = data.nick
	self.roles = data.roles -- raw table of IDs
end

function Member:createPresence(data)
	self.status = data.status
	if self.game and data.game then
		for k, v in pairs(self.game) do
			self.game[k] = data.game[k]
		end
	else
		self.game = data.game
	end
end

function Member:updatePresence(data)
	self:createPresence(data)
	self.user:update(data.user)
end

-- User-compatability methods --

function Member:getMembership(guild)
	return self.user:getMembership(guild or self.guild)
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

function Member:setNickname(nickname)
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {nick = nickname or ''})
	if success then self.nick = nickname end
	return success
end

function Member:setRoles(roles)
	if type(roles) == 'table' then
		local tbl = {}
		if roles.iter then
			for role in roles:iter() do
				table.insert(tbl, role.id)
			end
		elseif roles.__name == 'Role' then
			table.insert(tbl, roles.id)
		else
			for _, role in pairs(roles) do
				if role.__name == 'Role' then
					table.insert(tbl, role.id)
				end
			end
		end
		roles = tbl
	end
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {roles = roles or {}})
	if success then self.roles = roles end
	return success
end

function Member:setMute(mute)
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {mute = mute or false})
	if success then self.mute = mute end
	return success
end

function Member:setDeaf(deaf)
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {deaf = deaf or false})
	if success then self.deaf = deaf end
	return success
end

function Member:setVoiceChannel(channel)
	local success = self.client.api:modifyGuildMember(self.parent.id, self.user.id, {channel_id = channel.id})
	return success
end

function Member:getRoles()
	local roles = self.guild.roles
	return coroutine.wrap(function()
		for _, id in ipairs(self.roles) do
			coroutine.yield(roles:get(id))
		end
	end)
end

Member.setNick = Member.setNickname

return Member
