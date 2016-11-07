local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local clamp = math.clamp
local insert, concat = table.insert, table.concat
local wrap, yield = coroutine.wrap, coroutine.yield

local TextChannel, property, method, cache = class('TextChannel', Channel)
TextChannel.__description = "Abstract base class for guild and private text channels."

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	local client = self._parent._parent or self._parent
	self._messages = OrderedCache({}, Message, 'id', client._options.messageLimit, self)
	-- abstract class, don't call update
end

function TextChannel:_update(data)
	Channel._update(self, data)
end

local function _messageIterator(self, success, data)
	if not success then return function() end end
	return wrap(function()
		for i = #data, 1, -1 do
			yield(Message(data[i], self))
		end
	end)
end

local function loadMessages(self, limit)
	local query = limit and {limit = clamp(limit, 1, 100)}
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	if success then
		for i = #data, 1, -1 do
			self._messages:new(data[i])
		end
	end
	return success
end

local function getMessageById(self, id)
	local message = self._messages:get(id)
	if message then return message end
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessage(self.id, id)
	if success then return Message(data, self) end
end

local function _getMessageHistory(self, query)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	return _messageIterator(self, success, data)
end

local function getMessageHistory(self, limit)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return _getMessageHistory(self, query)
end

local function getMessageHistoryBefore(self, message, limit)
	local query = {before = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return _getMessageHistory(self, query)
end

local function getMessageHistoryAfter(self, message, limit)
	local query = {after = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return _getMessageHistory(self, query)
end

local function getMessageHistoryAround(self, message, limit)
	local query = {around = message._id, limit = limit and clamp(limit, 2, 100) or nil}
	return _getMessageHistory(self, query)
end

local function getPinnedMessages(self)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getPinnedMessages(self._id)
	return _messageIterator(self, success, data)
end

local function sendMessage(self, content, mentions, tts, nonce)
	if type(mentions) == 'table' then
		local strings = {}
		if mentions.iter then
			for obj in mentions:iter() do
				if obj.getMentionString then
					insert(strings, obj:getMentionString())
				end
			end
		elseif mentions.getMentionString then
			insert(strings, mentions:getMentionString())
		else
			for _, obj in pairs(mentions) do
				if obj.getMentionString then
					insert(strings, obj:getMentionString())
				end
			end
		end
		insert(strings, content)
		content = concat(strings, ' ')
	end
	local client = self._parent._parent or self._parent
	local success, data = client._api:createMessage(self._id, {
		content = content, tts = tts, nonce = nonce
	})
	if success then return self._messages:new(data, self) end
end

local function _bulkDelete(self, query)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	if success then
		if #data == 1 then
			return (client._api:deleteMessage(self._id, data[1].id))
		else
			local messages = {}
			for _, message_data in ipairs(data) do
				insert(messages, message_data.id)
			end
			return (client._api:bulkDeleteMessages(self._id, {messages = messages}))
		end
	end
end

local function bulkDelete(self, limit)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return _bulkDelete(self, query)
end

local function bulkDeleteAfter(self, message, limit)
	local query = {after = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return _bulkDelete(self, query)
end

local function bulkDeleteBefore(self, message, limit)
	local query = {before = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return _bulkDelete(self, query)
end

local function bulkDeleteAround(self, message, limit)
	local query = {around = message._id, limit = limit and clamp(limit, 2, 100) or nil}
	return _bulkDelete(self, query)
end

local function broadcastTyping(self)
	local client = self._parent._parent or self._parent
	return (client._api:triggerTypingIndicator(self._id))
end

-- messages --

local function getMessageCount(self)
	return self._messages._count
end

local function getMessages(self, key, value)
	return self._messages:getAll(key, value)
end

local function getMessage(self, key, value)
	return self._messages:get(key, value)
end

local function findMessage(self, predicate)
	return self._messages:find(predicate)
end

local function findMessages(self, predicate)
	return self._messages:findAll(predicate)
end

property('pinnedMessages', getPinnedMessages, nil, 'function', "Iterator for all of the pinned messages in the channel")

method('broadcastTyping', broadcastTyping, nil, "Causes the 'User is typing...' indicator to show in the channel.")
method('getMessageById', getMessageById, 'id', "Returns a message from the channel cache or from Discord if it is not cached.")
method('loadMessages', loadMessages, '[limit]', "Downloads 1 to 100 (default: 50) of the channel's most recent messages into the channel cache.")
method('sendMessage', sendMessage, 'content[, mentions, tts, nonce]', "Sends a message to the channel.")

method('getMessageHistory', getMessageHistory, '[limit]', 'Returns an iterator 1 to 100 (default: 50) of the most recent messages in the channel.')
method('getMessageHistoryBefore', getMessageHistoryBefore, 'message[, limit]', 'Get message history before a specific message.')
method('getMessageHistoryAfter', getMessageHistoryAfter, 'message[, limit]', 'Get message history after a specific message.')
method('getMessageHistoryAround', getMessageHistoryAround, 'message[, limit]', 'Get message history around a specific message.')

method('bulkDelete', bulkDelete, '[limit]', 'Permanently deletes 1 to 100 (default: 50) of the most recent messages from the channel.')
method('bulkDeleteAfter', bulkDeleteAfter, 'message[, limit]', 'Bulk delete after a specific message.')
method('bulkDeleteBefore', bulkDeleteBefore, 'message[, limit]', 'Bulk delete before a specific message.')
method('bulkDeleteAround', bulkDeleteAround, 'message[, limit]', 'Bulk delete around a specific message.')

cache('Message', getMessageCount, getMessage, getMessages, findMessage, findMessages)

return TextChannel
