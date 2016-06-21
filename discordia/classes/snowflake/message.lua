local User = require('./user')
local Base = require('./base')
local endpoints = require('../../endpoints')
local dateToTime = require('../../utils').dateToTime

local Message = class('Message', Base)

function Message:__init(data, channel)

	Base.__init(self, data.id, channel.client)

	self.channel = channel -- TextChannel, self explanatory
	self.server = channel.server -- Server, self explanatory

	self.nonce = data.nonce -- string
	self.embeds = data.embeds -- table, self explanatory
	self.content = data.content -- string, self explanatory
	self.timestamp = dateToTime(data.timestamp) -- string, self explanatory
	self.attachments = data.attachents -- table, self explanatory

	self.author = self.channel.recipient or self.server:getMemberById(data.author.id) -- Member, user who sent the message

	self.mentions = {members = {}, channels = {}, roles = {}} -- table, a table of tables full of mentions

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
		self.mentions.roles[self.server.id] = self.server.defaultRole
	end

end

function Message:_update(data)

	self.embeds = data.embeds -- table, self explanatory
	self.content = data.content or self.content -- string, self explanatory
	self.mentions = data.mentions or self.mentions -- table, self explanatory
	self.attachments = data.attachents or self.attachments -- table, self explanatory
	if data.editedTimestamp then
		self.editedTimestamp = dateToTime(data.editedTimestamp) -- number, self explanatory
	end
	self.mentionEveryone = data.mentionEveryone or self.mentionEveryone -- boolean, self explanatory

end

-- this function attempts to edit the message so that it contains the specified content
-- this currently only works on messages sent by your bot
-- this does not work on other users' messages
-- content should be a string

function Message:setContent(content)
	local body = {content = content}
	self.client:request('PATCH', {endpoints.channels, self.channel.id, 'messages', self.id}, body)
end

-- this function deletes the message if you have the correct permissions
-- this will not work in private channels
-- however, even in private channels, this will always work for your messages

function Message:delete()
	self.client:request('DELETE', {endpoints.channels, self.channel.id, 'messages', self.id})
end

-- returns true if the message mentions the specified member
-- false otherwise

function Message:mentionsMember(member)
	if self.mentions.members[member.id] then
		return true
	else
		return false
	end
end

-- returns true if the message mentions the specified role
-- false otherwise

function Message:mentionsRole(role)
	if self.mentions.roles[role.id] then
		return true
	else
		return false
	end
end

-- returns true if the message mentions the specified channel
-- false otherwise

function Message:mentionsChannel(channel)
	if self.mentions.channels[channel.id] then
		return true
	else
		return false
	end
end

-- a message starts out unread
-- this marks it read
-- note this does not work with bot users

function Message:acknowledge()
	self.client:request('POST', {endpoints.channels, self.channel.id, 'messages', self.id, 'ack'}, {})
end

return Message
