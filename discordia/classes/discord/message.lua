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
	self.channelId = data.channelId -- string
	self.attachments = data.attachents -- table

	self.author = self.channel.recipient or self.server:getMemberById(data.author.id)

	self.mentions = {members = {}, channels = {}, roles = {}}

	for _, memberData in ipairs(data.mentions) do
		local member = self.server.members[memberData.id]
		self.mentions.members[memberData.id] = member
	end

	for _, roleId in ipairs(data.mentionRoles) do
		local role = self.server.roles[roleId]
		self.mentions.roles[roleId] = role
	end

	for mention in self.content:gmatch('<#.->') do
		local channelId = mention:sub(3, -2)
		local channel = self.server.channels[channelId]
		self.mentions.channels[channelId] = channel
	end

	if data.mentionEveryone then
		self.mentions.roles[server.id] = server.defaultRole
	end

end

function Message:_update(data)

	self.embeds = data.embeds
	self.content = data.content or self.content
	self.mentions = data.mentions or self.mentions
	self.attachments = data.attachents or self.attachments
	self.editedTimestamp = dateToTime(data.editedTimestamp or self.editedTimestamp)
	self.mentionEveryone = data.mentionEveryone or self.mentionEveryone

end

function Message:setContent(content)
	local body = {content = content}
	self.client:request('PATCH', {endpoints.channels, self.channelId, 'messages', self.id}, body)
end

function Message:delete()
	self.client:request('DELETE', {endpoints.channels, self.channelId, 'messages', self.id})
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
	self.client:request('POST', {endpoints.channels, self.channelId, 'messages', self.id, 'ack'}, {})
end

return Message
