local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local clamp = math.clamp
local insert, concat = table.insert, table.concat
local wrap, yield = coroutine.wrap, coroutine.yield

local function messageIterator(success, data, parent)
	if not success then return function() end end
	return wrap(function()
		for i = #data, 1, -1 do
			yield(Message(data[i], parent))
		end
	end)
end

local TextChannel, property = class('TextChannel', Channel)

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	local client = self._parent._parent or self._parent
	self._messages = OrderedCache({}, Message, 'id', client._options.messageLimit, self)
	-- abstract class, don't call update
end

function TextChannel:_update(data)
	Channel._update(self, data)
end

function TextChannel:loadMessages(limit)
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

local function getMessageHistory(self, query)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	return messageIterator(success, data, self)
end

function TextChannel:getMessageHistory(limit)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryBefore(message, limit)
	local query = {before = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAfter(message, limit)
	local query = {after = message._id, limit = limit and clamp(limit, 1, 100) or nil}
	return getMessageHistory(self, query)
end

function TextChannel:getMessageHistoryAround(message, limit)
	local query = {around = message._id, limit = limit and clamp(limit, 2, 100) or nil}
	return getMessageHistory(self, query)
end

property('pinnedMessages', function(self)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getPinnedMessages(self._id)
	return messageIterator(success, data, self)
end, nil, 'function', "Iterator for all of the pinned messages in the channel")

function TextChannel:sendMessage(content, mentions, tts, nonce)
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

function TextChannel:bulkDelete(messages)
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

function TextChannel:broadcastTyping()
	local client = self._parent._parent or self._parent
	local success, data = client._api:triggerTypingIndicator(self._id)
	return success
end

-- messages --

property('messageCount', function(self, key, value)
	return self._messages._count
end, nil, 'number', "How many messages are cached for the channel")

property('messages', function(self, key, value)
	return self._messages:getAll(key, value)
end, nil, 'function', "Iterator for the cached messages in the channel")

function TextChannel:getMessage(key, value)
	return self._messages:get(key, value)
end

function TextChannel:findMessage(predicate)
	return self._messages:find(predicate)
end

function TextChannel:findMessages(predicate)
	return self._messages:findAll(predicate)
end

return TextChannel
