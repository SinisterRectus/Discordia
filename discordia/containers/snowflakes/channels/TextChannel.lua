local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local clamp = math.clamp
local insert, concat = table.insert, table.concat
local wrap, yield = coroutine.wrap, coroutine.yield

local TextChannel, property, method = class('TextChannel', Channel)
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
		local tbl = {}
		if mentions.iter then
			for obj in mentions:iter() do
				if obj.getMentionString then
					insert(tbl, obj:getMentionString())
				end
			end
		elseif mentions.getMentionString then
			insert(tbl, mentions:getMentionString())
		else
			for _, obj in pairs(mentions) do
				if obj.getMentionString then
					insert(tbl, obj:getMentionString())
				end
			end
		end
		insert(tbl, content)
		content = concat(tbl, ' ')
	end
	local client = self._parent._parent or self._parent
	local success, data = client._api:createMessage(self._id, {
		content = content, tts = tts, nonce = nonce
	})
	if success then return self._messages:new(data, self) end
end

local function bulkDelete(self, messages)
	local array = {}
	if messages.iter then
		for message in messages:iter() do
			insert(array, message._id)
		end
	else
		for _, message in pairs(messages) do
			insert(array, message._id)
		end
	end
	local client = self._parent._parent or self._parent
	local success, data = client._api:bulkDeleteMessages(self._id, {messages = array})
	return success
end

local function broadcastTyping()
	local client = self._parent._parent or self._parent
	local success, data = client._api:triggerTypingIndicator(self._id)
	return success
end

-- messages --

local function getMessageCount(self, key, value)
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

property('messages', getMessages, nil, 'function', "Iterator for the cached messages in the channel")
property('messageCount', getMessageCount, nil, 'number', "How many messages are cached for the channel")
property('pinnedMessages', getPinnedMessages, nil, 'function', "Iterator for all of the pinned messages in the channel")

method('broadcastTyping', broadcastTyping, nil, "Causes the 'User is typing...' indicator to show in the channel.")
method('getMessages', getMessages, 'key, value', "Returns an iterator for all cached messages that match the (key, value) pair")
method('getMessage', getMessage, '[key,] value]', "Returns the first cached message that matches the (key, value) pair.")
method('findMessage', findMessage, 'predicate', "Returns the first cached message that satisfies a predicate.")
method('findMessages', findMessages, 'predicate', "Returns all cached messages that satisfy a predicate.")
method('loadMessages', loadMessages, '[limit]', "Downloads 1 to 100 (default: 50) of the channel's most recent messages into the channel cache.")
method('getMessageHistory', getMessageHistory, '[limit]', 'Returns an iterator for the most recent messages in the channel.')
method('getMessageHistoryBefore', getMessageHistoryBefore, 'message[, limit]', 'Returns an iterator for the messages before a specific message.')
method('getMessageHistoryAfter', getMessageHistoryAfter, 'message[, limit]', 'Returns an iterator for the messages after a specific message.')
method('getMessageHistoryAround', getMessageHistoryAround, 'message[, limit]', 'Returns an iterator for the messages around a specific message.')
method('bulkDelete', bulkDelete, 'messages', 'Permanently deletes a table, cache, or deque of messages from the channel.')
method('sendMessage', sendMessage, 'content[, mentions, tts, nonce]', "Sends a message to the channel.")

return TextChannel
