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
	return self.messages:iter()
end

return TextChannel
