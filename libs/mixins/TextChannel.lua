local methods = {}

function methods:getMessage(id)
	return self.client:getChannelMessage(self.id, id)
end

function methods:getFirstMessage()
	local messages, err = self.client:getChannelMessages(self.id, 1, 'after', self.id)
	if messages then
		if messages[1] then -- NOTE: this might not always be an array
			return messages[1]
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function methods:getLastMessage()
	local messages, err = self.client:getChannelMessages(self.id, 1)
	if messages then
		if messages[1] then -- NOTE: this might not always be an array
			return messages[1]
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function methods:getMessages(limit, whence, messageId)
	return self.client:getChannelMessages(self.id, limit, whence, messageId)
end

function methods:getPinnedMessages()
	return self.client:getPinnedMessages(self.id)
end

function methods:triggerTyping()
	return self.client:triggerTypingIndicator(self.id)
end

function methods:send(payload)
	return self.client:createMessage(self.id, payload)
end

local getters = {}

return {
	methods = methods,
	getters = getters,
}
