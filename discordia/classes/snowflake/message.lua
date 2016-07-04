local User = require('./user')
local Base = require('./base')
local endpoints = require('../../endpoints')
local dateToTime = require('../../utils').dateToTime

local Message = class('Message', Base)

function Message:__init(data, channel)

	Base.__init(self, data.id, channel.client)

	self.channel = channel
	self.server = channel.server

	self.nonce = data.nonce -- string
	self.embeds = data.embeds -- table
	self.content = data.content -- string
	self.timestamp = dateToTime(data.timestamp) -- string
	self.attachments = data.attachents -- table

	if self.channel.isPrivate then
		if data.author.id == self.client.user.id then
			self.author = self.client.user
		else
			self.author = self.channel.recipient
		end
	else
		self.author = self.server:getMemberById(data.author.id)
		local mentions = {members = {}, roles = {}, channels = {}}
		local server = self.server
		for _, data in ipairs(data.mentions) do
			local member = server:getMemberById(data.id)
			if member then mentions.members[member.id] = member end
		end
		for _, id in ipairs(data.mentionRoles) do
			local role = server:getRoleById(id)
			if role then mentions.roles[role.id] = role end
		end
		for mention in self.content:gmatch('<#.->') do
			local channel = server:getChannelById(mention:sub(3, -2))
			if channel then mentions.channels[channel.id] = channel end
		end
		if data.mentionEveryone then
			mentions.roles[self.server.id] = self.server.defaultRole
		end
		self.mentions = mentions
	end

end

function Message:_update(data)

	self.embeds = data.embeds
	self.content = data.content or self.content
	self.mentions = data.mentions or self.mentions
	self.attachments = data.attachents or self.attachments
	if data.editedTimestamp then
		self.editedTimestamp = dateToTime(data.editedTimestamp)
	end
	self.mentionEveryone = data.mentionEveryone or self.mentionEveryone

end

function Message:setContent(content)
	local body = {content = content}
	self.client:request('PATCH', {endpoints.channels, self.channel.id, 'messages', self.id}, body)
end

function Message:delete()
	self.client:request('DELETE', {endpoints.channels, self.channel.id, 'messages', self.id})
end

function Message:mentionsMember(member)
	if self.mentions.members[member.id] then
		return true
	else
		return false
	end
end

function Message:mentionsRole(role)
	if self.mentions.roles[role.id] then
		return true
	else
		return false
	end
end

function Message:mentionsChannel(channel)
	if self.mentions.channels[channel.id] then
		return true
	else
		return false
	end
end

function Message:acknowledge()
	self.client:request('POST', {endpoints.channels, self.channel.id, 'messages', self.id, 'ack'}, {})
end

return Message
