local Base = require('./base')
local Deque = require('../deque')
local Server = require('./server')
local Message = require('./message')
local endpoints = require('../../endpoints')

local TextChannel = class('TextChannel', Base)

function TextChannel:__init(data, client)

	Base.__init(self, data.id, client)

	self.isPrivate = data.isPrivate
	self.lastMessageId = data.lastMessageId

	self.messages = {}
	self.deque = Deque()

end

function TextChannel:createMessage(content, mentions)
	if mentions and not self.isPrivate then
		local words = {}
		for _, obj in ipairs(mentions) do
			local n = obj.__name
			local s = self.server
			if n == 'User' or n == 'Member' and s.members[obj.id] then
				table.insert(words, string.format('<@%s>', obj.id))
			elseif n == 'Role' and s.roles[obj.id] then
				table.insert(words, string.format('<@&%s>', obj.id))
			elseif n == 'ServerTextChannel' and s.channels[obj.id] then
				table.insert(words, string.format('<#%s>', obj.id))
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

function TextChannel:getMessageHistory()
	local data = self.client:request('GET', {endpoints.channels, self.id, 'messages'})
	local messages = {}
	for _, messageData in ipairs(data) do
		table.insert(messages, Message(messageData, self))
	end
	return messages
end

function TextChannel:getMessageById(id)
	return self.messages[id]
end

return TextChannel
