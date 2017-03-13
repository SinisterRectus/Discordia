local Message = require('../Message')
local GuildChannel = require('./GuildChannel')
local TextChannel = require('./TextChannel')
local Webhook = require('../Webhook')

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

local function getMentionString(self)
	return format('<#%s>', self._id)
end

local function setTopic(self, topic)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {topic = topic})
	if success then self._topic = data.topic end
	return success
end

local function _bulkDelete(self, query, predicate)
	local client = self._parent._parent or self._parent
	local success, data = client._api:getChannelMessages(self._id, query)
	local ret = {}
	if success then
		predicate = type(predicate) == 'function' and predicate
		local ids = {}
		for _, v in ipairs(data) do
			local m = Message(v, self)
			if not predicate or predicate(m) then
				insert(ids, v.id)
				insert(ret, m)
			end
		end
		local n = #ids
		if n == 1 then
			success = client._api:deleteMessage(self._id, ids[1])
		elseif n > 1 then
			success = client._api:bulkDeleteMessages(self._id, {messages = ids})
		end
		if not success then return function() end end
	end
	local i = 0
	return function()
		i = i + 1
		return ret[i]
	end
end

local function bulkDelete(self, limit, predicate)
	local query = limit and {limit = clamp(limit, 1, 100)}
	return _bulkDelete(self, query, predicate)
end

local function bulkDeleteAfter(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {after = id, limit = limit and clamp(limit, 1, 100) or nil}
	return _bulkDelete(self, query, predicate)
end

local function bulkDeleteBefore(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {before = id, limit = limit and clamp(limit, 1, 100) or nil}
	return _bulkDelete(self, query, predicate)
end

local function bulkDeleteAround(self, message, limit, predicate)
	local t = type(message)
	local id = t == 'table' and message._id or t == 'string' and message or nil
	local query = {around = id, limit = limit and clamp(limit, 2, 100) or nil}
	return _bulkDelete(self, query, predicate)
end

local function createWebhook(self, name)
	local client = self._parent._parent
	local success, data = client._api:createWebhook(self._id, {name = name})
	return success and Webhook(data, client) or nil
end

local function getWebhooks(self)
	local client = self._parent._parent
	local success, data = client._api:getChannelWebhooks(self._id)
	if not success then return function() end end
	local i = 1
	return function()
		local v = data[i]
		if v then
			i = i + 1
			return Webhook(v, client)
		end
	end
end

property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('topic', '_topic', setTopic, 'string', "The channel topic (at the top of the channel in the Discord client)")
property('webhooks', getWebhooks, nil, 'function', "Returns an iterator for the channel's webhooks (not cached)")

method('bulkDelete', bulkDelete, '[limit[, predicate]]', 'Deletes 1 to 100 (default: 50) of the most recent messages from the channel and returns an iterator for them.', 'HTTP')
method('bulkDeleteAfter', bulkDeleteAfter, 'message[, limit[, predicate]]', 'Bulk delete after a specific message or ID.', 'HTTP')
method('bulkDeleteBefore', bulkDeleteBefore, 'message[, limit[, predicate]]', 'Bulk delete before a specific message or ID.', 'HTTP')
method('bulkDeleteAround', bulkDeleteAround, 'message[, limit[, predicate]]', 'Bulk delete around a specific message or ID.', 'HTTP')
method('createWebhook', createWebhook, 'name', 'Creates a new webhook for the channel.', 'HTTP')

return GuildTextChannel
