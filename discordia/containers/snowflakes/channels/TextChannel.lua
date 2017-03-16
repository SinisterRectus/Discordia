local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

local fs = require('coro-fs')
local http = require('coro-http')
local pathjoin = require('pathjoin')

local clamp = math.clamp
local format = string.format
local readFile = fs.readFile
local request = http.request
local splitPath = pathjoin.splitPath
local wrap, yield = coroutine.wrap, coroutine.yield
local insert, remove, concat = table.insert, table.remove, table.concat

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

local function _messageIterator(self, success, data, predicate)
	if not success then return function() end end
	predicate = type(predicate) == 'function' and predicate
	return wrap(function()
		for _, v in ipairs(data) do
			local m = Message(v, self)
			if not predicate or predicate(m) then
				yield(m)
			end
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

local function _getMessageHistory(self, query, predicate)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	return _messageIterator(self, success, data, predicate)
end

local function getMessageHistory(self, limit, predicate)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return _getMessageHistory(self, query, predicate)
end

local function getMessageHistoryBefore(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {before = id, limit = limit and clamp(limit, 1, 100) or nil}
	return _getMessageHistory(self, query, predicate)
end

local function getMessageHistoryAfter(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {after = id, limit = limit and clamp(limit, 1, 100) or nil}
	return _getMessageHistory(self, query, predicate)
end

local function getMessageHistoryAround(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {around = id, limit = limit and clamp(limit, 2, 100) or nil}
	return _getMessageHistory(self, query, predicate)
end

local function getPinnedMessages(self)
	local client = self._parent._parent or self._parent
	return _messageIterator(self, client._api:getPinnedMessages(self._id))
end

local function getFirstMessage(self)
	return _getMessageHistory(self, {after = '0', limit = 1})() or nil
end

local function getLastMessage(self)
	return _getMessageHistory(self, {limit = 1})() or nil
end

-- begin send message --

-- overhaul planned for 2.0

local function parseMentions(content, mentions)
	if type(mentions) == 'table' then
		local strings = {}
		if mentions.getMentionString then
			insert(strings, mentions:getMentionString())
		elseif mentions.iter then
			for obj in mentions:iter() do
				if obj.getMentionString then
					insert(strings, obj:getMentionString())
				end
			end
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
	return content
end

local function parseFile(filename, file, client)
	if type(file) == 'string' then
		local data, err
		if file:find('https?://') == 1 then
			err, data = request('GET', file)
			err = err.code > 299 and format('%s / %s / %s', err.code, err.reason, file)
		else
			data, err = readFile(file)
		end
		if err then
			client:warning(err)
		else
			return {type(filename) == 'string' and filename or remove(splitPath(file)), data}
		end
	elseif type(file) == 'table' and type(file[1]) == 'string' and type(file[2]) == 'string' then
		return file
	end
end

local function parseFiles(filename, file, files, client)
	local f1 = parseFile(filename, file, client)
	local ret = f1 and {f1} or nil
	if type(files) == 'table' then
		ret = ret or {}
		for _, v in ipairs(files) do
			local f = parseFile(nil, v, client)
			if f then insert(ret, f) end
		end
	end
	return ret
end

local function sendMessage(self, content, ...) -- mentions, tts
	local client = self._parent._parent or self._parent
	local payload, files
	if select('#', ...) > 0 then
		client:warning('Multiple argument usage for TextChannel:sendMessage is deprecated. Use a table instead.')
		payload = {content = parseMentions(content, select(1, ...)), tts = select(2, ...)}
	else
		local arg = content
		local t = type(arg)
		if t == 'string' then
			payload = {content = arg}
		elseif t == 'table' then
			payload = {
				content = parseMentions(arg.content, arg.mentions),
				tts = arg.tts,
				nonce = arg.nonce,
				embed = arg.embed,
			}
			files = parseFiles(arg.filename, arg.file, arg.files, client)
		end
	end
	local success, data = client._api:createMessage(self._id, payload, files)
	return success and self._messages:new(data) or nil
end

-- end send message --

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
	local message = self._messages:get(key, value)
	if message or value then return message end
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessage(self.id, key)
	return success and Message(data, self) or nil
end

local function findMessage(self, predicate)
	return self._messages:find(predicate)
end

local function findMessages(self, predicate)
	return self._messages:findAll(predicate)
end

property('pinnedMessages', getPinnedMessages, nil, 'function', "Iterator for all of the pinned messages in the channel")
property('firstMessage', getFirstMessage, nil, 'Message', "The first message found in the channel via HTTP (not cached).")
property('lastMessage', getLastMessage, nil, 'Message', "The last message found in the channel via HTTP (not cached).")

method('broadcastTyping', broadcastTyping, nil, "Causes the 'User is typing...' indicator to show in the channel.", 'HTTP')
method('loadMessages', loadMessages, '[limit]', "Downloads 1 to 100 (default: 50) of the channel's most recent messages into the channel cache.", 'HTTP')
method('sendMessage', sendMessage, 'content', "Sends a message to the channel. Content is a string or table.", 'HTTP')

method('getMessageHistory', getMessageHistory, '[limit[, predicate]', 'Returns an iterator for up to 1 to 100 (default: 50) of the most recent messages in the channel.', 'HTTP')
method('getMessageHistoryBefore', getMessageHistoryBefore, 'message[, limit[, predicate]]', 'Get message history before a specific message or ID.', 'HTTP')
method('getMessageHistoryAfter', getMessageHistoryAfter, 'message[, limit[, predicate]]', 'Get message history after a specific message or ID.', 'HTTP')
method('getMessageHistoryAround', getMessageHistoryAround, 'message[, limit[, predicate]]', 'Get message history around a specific message or ID.', 'HTTP')

cache('Message', getMessageCount, getMessage, getMessages, findMessage, findMessages)

return TextChannel
