local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local function newCache(channel, data)
	local cache = OrderedCache({}, Message, 'id', math.huge, channel)
	for i = #data, 1, -1 do
		cache:new(data[i])
	end
	return cache
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
	return self.messages:iter()
end

function TextChannel:getMessageHistory(limit)
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit)
	if success then return newCache(self, data) end
end

function TextChannel:getMessageHistoryBefore(message, limit)
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit, 'before', message.id)
	if success then return newCache(self, data) end
end

function TextChannel:getMessageHistoryAfter(message, limit)
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit, 'after', message.id)
	if success then return newCache(self, data) end
end

function TextChannel:getMessageHistoryAround(message, limit)
	limit = math.clamp(limit or 50, 2, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit, 'around', message.id)
	if success then return newCache(self, data) end
end

function TextChannel:getPinnedMessages()
	local success, data = self.client.api:getPinnedMessages(self.id)
	if success then return newCache(self, data) end
end

function TextChannel:createMessage(content, mentions, tts, nonce)
	if type(mentions) == 'table' then
		local tbl = {}
		if mentions.iter then
			for obj in mentions:iter() do
				if obj.getMentionString then
					table.insert(tbl, obj:getMentionString())
				end
			end
		elseif mentions.getMentionString then
			table.insert(tbl, mentions:getMentionString())
		else
			for _, obj in pairs(mentions) do
				if obj.getMentionString then
					table.insert(tbl, obj:getMentionString())
				end
			end
		end
		table.insert(tbl, content)
		content = table.concat(tbl, ' ')
	end
	local success, data = self.client.api:createMessage(self.id, {
		content = content, tts = tts, nonce = nonce
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
