local Deque = require('../utils/deque')
local Base = require('./base')
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

function TextChannel:createMessage(content)
	local body = {content = content}
	local data = self.client:request('POST', {endpoints.channels, self.id, 'messages'}, body)
	if data then return Message(data, self) end
end

function TextChannel:sendMessage(content) -- alias for createMessage
	return self:createMessage(content)
end

function TextChannel:update(data)
	self.name = data.name -- text
	self.position = data.position -- number
	self.topic = topic -- text
end

function TextChannel:setTopic(topic)
	local body = {name = self.name, position = self.position, topic = topic}
	local data = local data = self.client:request('PATCH', {endpoints.channels, self.id, 'messages'}, body)	
	
	return data.topic
end

function TextChannel:upRank()
	local body = {name = self.name, position = self.position + 1, topic = topic}
	local data = local data = self.client:request('PATCH', {endpoints.channels, self.id, 'messages'}, body)	
	
	return data.topic
end

function TextChannel:downRank()
	local body = {name = self.name, position = self.position - 1, topic = topic}
	local data = local data = self.client:request('PATCH', {endpoints.channels, self.id, 'messages'}, body)	
	
	return data.topic
end

function TextChannel:delete()
	self.client:request('DELETE', {endpoints.channels, self.id})
end

function TextChannel:getMessageHistory()
	return self.client:request('GET', {endpoints.channels, self.id, 'messages'})
end

function TextChannel:getMessageById(id)
	return self.messages[id]
end

return TextChannel
