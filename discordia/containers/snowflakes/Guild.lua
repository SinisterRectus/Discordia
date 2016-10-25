local Snowflake = require('../Snowflake')
local Role = require('./Role')
local User = require('./User')
local Member = require('./Member')
local GuildTextChannel = require('./channels/GuildTextChannel')
local GuildVoiceChannel = require('./channels/GuildVoiceChannel')
local Invite = require('../Invite')
local VoiceState = require('../VoiceState')
local Cache = require('../../utils/Cache')

local Guild, accessors = class('Guild', Snowflake)

accessors.me = function(self) return self.members:get(self.client.user.id) end
accessors.owner = function(self) return self.members:get(self.ownerId) end
accessors.afkChannel = function(self) return self.voiceChannels:get(self.afkChannelId) end
accessors.defaultRole = function(self) return self.roles:get(self.id) end
accessors.defaultChannel = function(self) return self.textChannels:get(self.id) end

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	if data.unavailable then
		self.unavailable = true
	else
		self:makeAvailable(data)
	end
end

function Guild:makeAvailable(data)

	self.unavailable = false

	self.large = data.large
	self.joinedAt = data.joined_at
	self.memberCount = data.member_count

	self.roles = Cache(data.roles or {}, Role, 'id', self)
	self.members = Cache(data.members or {}, Member, 'id', self)
	self.voiceStates = Cache(data.voice_states or {}, VoiceState, 'sessionId', self)
	self.textChannels = Cache({}, GuildTextChannel, 'id', self)
	self.voiceChannels = Cache({}, GuildVoiceChannel, 'id', self)

	if data.presences then
		self:loadMemberPresences(data.presences)
	end

	if data.channels then
		for _, data in ipairs(data.channels) do
			if data.type == 'text' then
				self.textChannels:new(data)
			elseif data.type == 'voice' then
				self.voiceChannels:new(data)
			end
		end
	end

	if self.large and self.client.options.fetchMembers then
		self:requestMembers()
	end

	self:update(data)

end

function Guild:update(data)
	self.name = data.name
	self.icon = data.icon
	self.splash = data.splash
	self.region = data.region
	self.ownerId = data.owner_id
	self.mfaLevel = data.mfa_level
	self.afkTimeout = data.afk_timeout
	self.afkChannelId = data.afk_channel_id
	self.verificationLevel = data.verification_level
	self.vip = next(data.features) and true or false
	-- self.emojis = data.emojis -- TODO
	-- self.features = data.features -- TODO
end

function Guild:loadMemberPresences(data)
	for _, presence in ipairs(data) do
		local member = self.members:get(presence.user.id)
		member:createPresence(presence)
	end
end

function Guild:updateMemberPresence(data)
	local member = self.members:get(data.user.id)
	if member then
		member:updatePresence(data)
	else
		member = self.members:new(data)
		member:createPresence(data)
	end
	return member
end

function Guild:requestMembers()
	self.client.socket:requestGuildMembers(self.id)
	if self.client.loading then
		self.client.loading.chunks[self.id] = true
	end
end

function Guild:addMember(user) -- limit use, requires guild.join scope
	local success, data = self.client.api:addGuildMember(self.id, user.id)
	if success then return self.members:new(data) end
end

function Guild:setName(name)
	local success, data = self.client.api:modifyGuild(self.id, {name = name})
	if success then self.name = data.name end
	return success
end

function Guild:setRegion(region)
	local success, data = self.client.api:modifyGuild(self.id, {region = region})
	if success then self.region = data.region end
	return success
end

function Guild:setIcon(icon)
	local success, data = self.client.api:modifyGuild(self.id, {icon = icon})
	if success then self.icon = data.icon end
	return success
end

function Guild:setOwner(user)
	local success, data = self.client.api:modifyGuild(self.id, {owner_id = user.id})
	if success then self.ownerId = data.owner_id end
	return success
end

function Guild:setAfkTimeout(timeout)
	local success, data = self.client.api:modifyGuild(self.id, {afk_timeout = timeout})
	if success then self.afkTimeout = data.afk_timeout end
	return success
end

function Guild:setAfkChannel(channel)
	local success, data = self.client.api:modifyGuild(self.id, {afk_channel_id = channel and channel.id or self.id})
	if success then self.afkChannelId = data.afk_channel_id end
	return success
end

function Guild:leave()
	local success, data = self.client.api:leaveGuild(self.id)
	return success
end

function Guild:delete()
	local success, data = self.client.api:deleteGuild(self.id)
	return success
end

function Guild:getBans()
	local success, data = self.client.api:getGuildBans(self.id)
	if success then
		local users = Cache({}, User, 'id', self.client)
		for _, v in ipairs(data) do
			users:new(v.user)
		end
		return users
	end
end

function Guild:banUser(user, messageDeleteDays)
	messageDeleteDays = messageDeleteDays and math.clamp(messageDeleteDays, 0, 7) or nil
	local success, data = self.client.api:createGuildBan(self.id, user.id, messageDeleteDays)
	return success
end

function Guild:unbanUser(user)
	local success, data = self.client.api:removeGuildBan(self.id, user.id)
	return success
end

function Guild:kickUser(user)
	local success, data = self.client.api:removeGuildMember(self.id, user.id)
	return success
end

function Guild:createTextChannel(name)
	local success, data = self.client.api:createGuildChannel(self.id, {name = name, type = 'text'})
	if success then return self.textChannels:new(data) end
end

function Guild:createVoiceChannel(name)
	local success, data = self.client.api:createGuildChannel(self.id, {name = name, type = 'voice'})
	if success then return self.voiceChannels:new(data) end
end

function Guild:createRole()
	local success, data = self.client.api:createGuildRole(self.id)
	if success then return self.roles:new(data) end
end

function Guild:getInvites()
	local success, data = self.client.api:getGuildInvites(self.id)
	if success then return Cache(data, Invite, 'code', self.client) end
end

-- convenience accessors --

function Guild:getRoleById(id)
	return self.roles:get(id)
end

function Guild:getRoleByName(name)
	return self.roles:get('name', name)
end

function Guild:getChannelById(id)
	return self:getTextChannelById(id) or self:getVoiceChannelById(id) or nil
end

function Guild:getTextChannelById(id)
	return self.textChannels:get(id)
end

function Guild:getVoiceChannelById(id)
	return self.voiceChannels:get(id)
end

function Guild:getChannelByName(name)
	return self:getTextChannelByName(name) or self:getVoiceChannelByName(name)
end

function Guild:getTextChannelByName(name)
	return self.textChannels:get('name', name)
end

function Guild:getVoiceChannelByName(name)
	return self.voiceChannels:get('name', name)
end

function Guild:getMemberById(id)
	return self.members:get(id)
end

function Guild:getMemberByName(name)
	return self.members:get('name', name)
end

function Guild:getVoiceStateById(sessionId)
	return self.voiceStates:get(sessionId)
end

function Guild:getMessageById(id)
	for channel in self:getTextChannels() do
		local message = channel.messages:get(id)
		if message then return message end
	end
end

-- convenience iterators --

function Guild:getRoles()
	return self.roles:iter()
end

function Guild:getChannels()
	return coroutine.wrap(function()
		for channel in self:getTextChannels() do
			coroutine.yield(channel)
		end
		for channel in self:getVoiceChannels() do
			coroutine.yield(channel)
		end
	end)
end

function Guild:getTextChannels()
	return self.textChannels:iter()
end

function Guild:getVoiceChannels()
	return self.voiceChannels:iter()
end

function Guild:getMembers()
	return self.members:iter()
end

function Guild:getVoiceStates()
	return self.voiceStates:iter()
end

Guild.getBannedUsers = Guild.getBans

return Guild
