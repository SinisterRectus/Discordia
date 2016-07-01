local Base = require('./base')
local Message = require('./message')
local endpoints = require('../../endpoints')
local PrivateChannel -- lazy require

local User = class('User', Base)

function User:__init(data, client)

	Base.__init(self, data.id, client)

	self.bot = data.bot or false
	self.avatar = data.avatar or ''
	self.username = data.username
	self.discriminator = data.discriminator
	self.name = self.nickname or self.username

	-- don't call update, it gets confused

end

function User:_update(data)
	self.avatar = data.avatar or ''
	self.username = data.username
	self.name = self.nickname or self.username
	self.discriminator = data.discriminator
end

function User:sendMessage(content)
	local channelBody = {recipient_id = self.id}
	local channelData = self.client:request('POST', {endpoints.me, 'channels'}, channelBody)
	if channelData then
		PrivateChannel = PrivateChannel or require('./privatechannel')
		local channel = PrivateChannel(channelData, self.client)
		local messageBody = {content = content}
		local messageData = self.client:request('POST', {endpoints.channels, channelData.id, 'messages'}, messageBody)
		if messageData then return Message(messageData, channel) end
	end
end

function User:ban(server) -- Server:banUser(user)
	self.client:request('PUT', {endpoints.servers, server.id, 'bans', self.id}, {})
end

function User:unban(server) -- Server:unbanUser(user)
	self.client:request('DELETE', {endpoints.servers, server.id, 'bans', self.id})
end

function User:kick(server) -- Server:kickUser(user), Member:kick()
	self.client:request('DELETE', {endpoints.servers, server.id, 'members', self.id})
end

function User:getAvatarUrl()
	if not self.avatar then return nil end
	return string.format('https://discordapp.com/api/users/%s/avatars/%s.jpg', self.id, self.avatar)
end

function User:getMentionString()
	return string.format('<@%s>', self.id)
end

return User
