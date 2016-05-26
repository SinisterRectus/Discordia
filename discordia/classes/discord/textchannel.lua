local Deque = require('../deque')
local Server = require('./server')
local Channel = require('./channel')
local Message = require('./message')
local endpoints = require('../../endpoints')

local TextChannel = class('TextChannel', Channel)

function TextChannel:__init(data, client)

	Channel.__init(self, data, client)

	self.isPrivate = data.isPrivate
	self.lastMessageId = data.lastMessageId

	self.messages = {}
	self.deque = Deque()

end

function TextChannel:createMessage(content, mentions)
	if mentions and not self.isPrivate then
		local words = {}
		for _, obj in pairs(mentions) do
			if obj.getMentionString then
				table.insert(words, obj:getMentionString())
			end
		end
		table.insert(words, content)
		content = table.concat(words, ' ')
	end
	local body = {content = content}
	local data = self.client:request('POST', {endpoints.channels, self.id, 'messages'}, body)
	if data then return Message(data, self) end
end

function TextChannel:sendMessage(content, mentions) -- alias for createMessage
	return self:createMessage(content, mentions)
end

function TextChannel:broadcastTyping()
	self.client:request('POST', {endpoints.channels, self.id, 'typing'}, {})
end

function TextChannel:getMessageHistory(limit)
	local data = self.client:request('GET', {endpoints.channels, self.id, string.format('messages?limit=%i', limit or 1)})
	local messages = {}
	for _, messageData in ipairs(data) do
		table.insert(messages, Message(messageData, self))
	end
	return messages
end

function TextChannel:bulkDelete(messages)
	local body = {messages = {}}
	for _, message in pairs(messages) do
		table.insert(body.messages, message.id)
	end
	self.client:request('POST', {endpoints.channels, self.id, 'messages', 'bulk_delete'}, body)
end

function TextChannel:getMessageById(id)
	return self.messages[id]
end

return TextChannel
