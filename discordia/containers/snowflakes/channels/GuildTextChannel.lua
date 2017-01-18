local Message = require('../Message')
local GuildChannel = require('./GuildChannel')
local TextChannel = require('./TextChannel')

local clamp = math.clamp
local insert = table.insert
local format = string.format

local GuildTextChannel, property, method = class('GuildTextChannel', TextChannel, GuildChannel)
GuildTextChannel.__description = "Represents a Discord guild text channel."

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
	GuildTextChannel._update(self, data)
	parent._parent._channel_map[self._id] = parent
end

function GuildTextChannel:_update(data)
	GuildChannel._update(self, data)
	TextChannel._update(self, data)
end

local function _messageIterator(self, success, data)
	if not success then return function() end end
	local i = 1
	return function()
		local v = data[i]
		if v then
			i = i + 1
			return Message(v, self)
		end
	end
end

local function getMentionString(self)
	return format('<#%s>', self._id)
end

local function setTopic(self, topic)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {topic = topic})
	if success then self._topic = data.topic end
	return success
end

local function _bulkDelete(self, query)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	if success then
		if #data == 1 then
			success = client._api:deleteMessage(self._id, data[1].id)
			return _messageIterator(self, success, data)
		else
			local messages = {}
			for _, message_data in ipairs(data) do
				insert(messages, message_data.id)
			end
			success = client._api:bulkDeleteMessages(self._id, {messages = messages})
			return _messageIterator(self, success, data)
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

property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('topic', '_topic', setTopic, 'string', "The channel topic (at the top of the channel in the Discord client)")

method('bulkDelete', bulkDelete, '[limit]', 'Deletes 1 to 100 (default: 50) of the most recent messages from the channel and returns an iterator for them.')
method('bulkDeleteAfter', bulkDeleteAfter, 'message[, limit]', 'Bulk delete after a specific message.')
method('bulkDeleteBefore', bulkDeleteBefore, 'message[, limit]', 'Bulk delete before a specific message.')
method('bulkDeleteAround', bulkDeleteAround, 'message[, limit]', 'Bulk delete around a specific message.')

return GuildTextChannel
