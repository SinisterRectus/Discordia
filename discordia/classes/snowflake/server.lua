local Role = require('./role')
local User = require('./user')
local Member = require('./member')
local Base = require('./base')
local Invite = require('../invite')
local endpoints = require('../../endpoints')
local VoiceState = require('../voicestate')
local ServerTextChannel = require('./servertextchannel')
local ServerVoiceChannel = require('./servervoicechannel')
local dateToTime = require('../../utils').dateToTime

local Server  = class("Server", Base)

function Server:__init(data, client)

	Base.__init(self, data.id, client)

	self.large = data.large -- boolean
	self.joinedAt = dateToTime(data.joinedAt) -- string

	if self.large then client.websocket:requestGuildMembers(self.id) end

	self.roles = {}
	self.members = {}
	self.channels = {}
	self.voiceStates = {}

	self.name = data.name -- string
	self.icon = data.icon -- string
	self.regionId = data.regionId -- string
	self.afkTimeout = data.afkTimeout -- number
	self.embedEnabled = data.embedChannelId-- boolean
	self.embedChannelId = data.embedChannelId -- string
	self.verificationLevel = data.verificationLevel -- number
	-- self.emojis = data.emojis -- need to handle
	-- self.features = data.features -- need to handle

	for _, roleData in ipairs(data.roles) do
		local role = Role(roleData, self)
		self.roles[role.id] = role
	end

	if data.members then
		for _, memberData in ipairs(data.members) do
			local member = Member(memberData, self)
			self.members[member.id] = member
		end
	end

	if data.presences then
		for _, memberData in ipairs(data.presences) do
			local member = self.members[memberData.user.id]
			if member then -- invisible member fix
				member:_update(memberData) -- status and game update
			end
		end
	end

	if data.channels then
		for _, channelData in ipairs(data.channels) do
			local channel
			if channelData.type == 'text' then
				channel = ServerTextChannel(channelData, self)
			elseif channelData.type == 'voice' then
				channel = ServerVoiceChannel(channelData, self)
			end
			self.channels[channel.id] = channel
		end
	end

	if data.voiceStates then
		for _, voiceData in ipairs(data.voiceStates) do
			local voiceState = VoiceState(voiceData, self)
			self.voiceStates[voiceState.sessionId] = voiceState
		end
	end

	self.me = self.members[client.user.id]
	self.owner = self.members[data.ownerId] -- string
	self.afkChannel = self.channels[data.afkChannelId] -- string
	self.defaultChannel = self.channels[self.id]
	self.defaultRole = self.roles[self.id]

end

function Server:_update(data)

	self.name = data.name -- string
	self.icon = data.icon -- string
	self.regionId = data.regionId -- string
	self.afkTimeout = data.afkTimeout -- number
	self.embedEnabled = data.embedChannelId-- boolean
	self.embedChannelId = data.embedChannelId -- string
	self.verificationLevel = data.verificationLevel -- number

	self.owner = self.members[data.ownerId] -- string
	self.afkChannel = self.channels[data.afkChannelId] -- string
	-- self.emojis = data.emojis -- need to handle
	-- self.features = data.features -- need to handle

	for _, roleData in ipairs(data.roles) do
		local role = Role(roleData, self)
		self.roles[role.id] = role
	end

end

function Server:setName(name)
	local body = {name = name}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:setRegion(regionId)
	local body = {region = regionId}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:setIcon(icon)
	local body = {icon = icon}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:setOwner(user)
	-- does the owner have to be a pre-existing member?
	local body = {owner_id = user.id}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:setAfkTimeout(timeout)
	local body = {afk_timeout = timeout}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:setAfkChannel(channel)
	local body = {afk_channel_id = channel.id}
	self.client:request('PATCH', {endpoints.servers, self.id}, body)
end

function Server:leave()
	self.client:request('DELETE', {endpoints.me, 'guilds', self.id})
end

function Server:delete()
	self.client:request('DELETE', {endpoints.servers, self.id})
end

function Server:getInvites()
	local inviteTable = self.client:request('GET', {endpoints.servers, self.id, 'invites'})
	if not inviteTable then return end
	local invites = {}
	for _, inviteData in ipairs(inviteTable) do
		local invite = Invite(inviteData, self)
		invites[invite.code] = invite
	end
	return invites
end

function Server:getBannedUsers()
	local banTable = self.client:request('GET', {endpoints.servers, self.id, 'bans'})
	if not banTable then return end
	local users = {}
	for _, banData in ipairs(banTable) do
		local user = User(banData.user, self.client)
		users[user.id] = user
	end
	return users
end

function Server:banUser(user) -- User:ban(server)
	self.client:request('PUT', {endpoints.servers, self.id, 'bans', user.id}, {})
end

function Server:unbanUser(user) -- User:unban(server)
	-- what if they are not banned?
	self.client:request('DELETE', {endpoints.servers, self.id, 'bans', user.id})
end

function Server:kickUser(user) -- User:kick(server)
	self.client:request('DELETE', {endpoints.servers, self.id, 'members', user.id})
end

function Server:getRoleById(id) -- Client:getRoleById(id)
	local role = self.roles[id]
	if role then return role end
	return nil
end

function Server:getRoleByName(name) -- Client:getRoleByName(name)
	for _, role in pairs(self.roles) do
		if role.name == name then
			return role
		end
	end
	return nil
end

function Server:createRole()
	local data = self.client:request('POST', {endpoints.servers, self.id, 'roles'}, {})
	if data then return Role(data, self) end
end

function Server:createTextChannel(name)
	local body = {name = name, type = 'text'}
	local data = self.client:request('POST', {endpoints.servers, self.id, 'channels'}, body)
	if data then return ServerTextChannel(data, self) end
end

function Server:createVoiceChannel(name)
	local body = {name = name, type = 'voice'}
	local data = self.client:request('POST', {endpoints.servers, self.id, 'channels'}, body)
	if data then return ServerVoiceChannel(data, self) end
end

function Server:getChannelById(id) -- Client:getChannelById(id)
	local channel = self.channels[id]
	if channel then return channel end
	return nil
end

function Server:getChannelByName(name) -- Client:getChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getTextChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.type == 'text' and channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getVoiceChannelByName(name)
	for _, channel in pairs(self.channels) do
		if channel.type == 'voice' and channel.name == name then
			return channel
		end
	end
	return nil
end

function Server:getMemberById(id) -- Client:getUserById(id)
	local member = self.members[id]
	if member then return member end
	return nil
end

function Server:getMemberByName(name) -- Client:getUserByName(name)
	for _, member in pairs(self.members) do
		if member.name == name then
			return member
		end
	end
	return nil
end

function Server:getMessageById(id) -- Client:getMessageById(id), Channel:getMessageById(id)
	for _, channel in pairs(self.channels) do
		local message = channel.messages[id]
		if message then return message end
	end
	return nil
end

return Server
