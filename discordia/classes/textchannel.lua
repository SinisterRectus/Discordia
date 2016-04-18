local Deque = require('./deque')
local Object = require('./object')
local Server = require('./server')
local Message = require('./message')
local endpoints = require('../endpoints')

class('TextChannel', Object)

function TextChannel:__init(data, client)

    Object.__init(self, data.id, client)

    self.isPrivate = data.isPrivate
    self.lastMessageId = data.lastMessageId

    self.messages = {}
    self.deque = Deque()

end

function TextChannel:createMessage(content)
    local body = {content = content}
    local data = self.client:request('POST', {endpoints.channels, self.id, 'messages'}, body)
    return Message(data, self) -- not the same object that is cached
end

function TextChannel:sendMessage(content) -- alias for createMessage
    return self:createMessage(content)
end

function TextChannel:getMessageHistory()
    return self.client:request('GET', {endpoints.channels, self.id, 'messages'})
end

function TextChannel:getMessageById(id)
    return self.messages[id]
end

return TextChannel
