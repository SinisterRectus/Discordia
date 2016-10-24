local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local function getMessageHistory(channel, limit, min, field, message)
	limit = math.clamp(limit or 50, min, 100)
	local success, data = channel.client.api:getChannelMessages(channel.id, limit, field, message and message.id)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, channel)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

local TextChannel = class('TextChannel', Channel)

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self.messages = OrderedCache({}, Message, 'id', self.client.options.maxMessages, self)
	TextChannel.update(self, data)
end

function TextChannel:update(data)
	self.lastMessageId = data.last_message_id
end

function TextChannel:getMessageById(id)
	return self.messages:get(id)
end

function TextChannel:getMessages()
	return self.messages:iterNewToOld()
end

function TextChannel:getMessageHistory(limit)
	return getMessageHistory(self, limit, 1)
end

function TextChannel:getMessageHistoryBefore(message, limit)
	return getMessageHistory(self, limit, 1, 'before', message)
end

function TextChannel:getMessageHistoryAfter(message, limit)
	return getMessageHistory(self, limit, 1, 'after', message)
end

function TextChannel:getMessageHistoryAround(message, limit)
	return getMessageHistory(self, limit, 2, 'around', message)
end

function TextChannel:getPinnedMessages()
	local success, data = self.client.api:getPinnedMessages(self.id)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, self)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

function TextChannel:createMessage(content, tts, nonce)
	local success, data = self.client.api:createMessage(self.id, {
		content = content, nonce = nonce, tts = tts
	})
	if success then return self.messages:new(data, self) end
end

function TextChannel:bulkDelete(messages)
	local array = {}
	if messages.iter then
		for message in messages:iter() do
			table.insert(array, message.id)
		end
	else
		for _, message in pairs(messages) do
			table.insert(array, message.id)
		end
	end
	local success, data = self.client.api:bulkDeleteMessages(self.id, {messages = array})
	return success
end

function TextChannel:broadcastTyping()
	local success, data = self.client.api:triggerTypingIndicator(self.id)
	return success
end

-- aliases--
TextChannel.sendMessage = TextChannel.createMessage

return TextChannel
