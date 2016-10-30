local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local clamp = math.clamp
local wrap, yield = coroutine.wrap, coroutine.yield

local function messageIterator(success, data, parent)
	if not success then return function() end end
	return wrap(function()
		for i = #data, 1, -1 do
			yield(Message(data[i], parent))
		end
	end)
end

local TextChannel = class('TextChannel', Channel)

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self.messages = OrderedCache({}, Message, 'id', self.client.options.messageLimit, self)
end

function TextChannel:_update(data)
	self.lastMessageId = data.last_message_id
end

function TextChannel:getMessageById(id)
	local message = self.messages:get(id)
	if not message and self.client.user.bot then
		local success, data = self.client.api:getChannelMessage(self.id, id)
		if success then message = Message(data, self) end
	end
	return message
end

function TextChannel:getMessages()
	return self.messages:iter()
end

local function getMessageHistory(message, query)
	local success, data = message.client.api:getChannelMessages(message.id, query)
	return messageIterator(success, data, message)
end

function TextChannel:getMessageHistory(limit)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryBefore(message, limit)
	local query = {before = message.id, limit = limit and clamp(limit, 1, 100) or nil}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAfter(message, limit)
	local query = {after = message.id, limit = limit and clamp(limit, 1, 100) or nil}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAround(message, limit)
	local query = {around = message.id, limit = limit and clamp(limit, 2, 100) or nil}
	return getMessageHistory(self, query)
end

function TextChannel:getPinnedMessages()
	local success, data = self.client.api:getPinnedMessages(self.id)
	return messageIterator(success, data, self)
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
