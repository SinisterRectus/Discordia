local Channel = require('../Channel')
local Message = require('../Message')
local OrderedCache = require('../../../utils/OrderedCache')

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
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, self)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

function TextChannel:getMessageHistoryBefore(message, limit)
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit, message.id, nil, nil)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, self)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

function TextChannel:getMessageHistoryAfter(message, limit)
	limit = math.clamp(limit or 50, 1, 100)
	local success, data = self.client.api:getChannelMessages(self.id, limit, nil, message.id, nil)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, self)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

function TextChannel:getMessageHistoryAround(message, limit)
	limit = math.clamp(limit or 50, 2, 100) -- lower limit is 2 for this one
	local success, data = self.client.api:getChannelMessages(self.id, limit, nil, nil, message.id)
	if success then
		local cache = OrderedCache({}, Message, 'id', math.huge, self)
		for i = #data, 1, -1 do
			cache:new(data[i])
		end
		return cache
	end
end

return TextChannel
