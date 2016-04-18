local User = require('./user')
local Object = require('./object')
local endpoints = require('../endpoints')

class('Message', Object)

function Message:__init(data, channel)

	Object.__init(self, data.id, channel.client)

	self.channel = channel
	self.server = channel.server

	self.nonce = data.nonce -- string
	self.embeds = data.embeds -- table
	self.content = data.content -- string
	self.mentions = data.mentions -- table
	self.timestamp = data.timestamp -- string
	self.channelId = data.channelId -- string
	self.attachments = data.attachents -- table
	self.mentionEveryone = data.mentionEveryone -- boolean

	self.author = self.channel.recipient or self.server:getMemberById(data.author.id)

end

function Message:update(data)

	self.embeds = data.embeds
	self.content = data.content or self.content
	self.mentions = data.mentions or self.mentions
	self.attachments = data.attachents or self.attachments
	self.editedTimestamp = data.editedTimestamp or self.editedTimestamp
	self.mentionEveryone = data.mentionEveryone or self.mentionEveryone

end

function Message:setContent(content)
	local body = {content = content}
	self.client:request('PATCH', {endpoints.channels, self.channelId, 'messages', self.id}, body)
end

function Message:delete()
	self.client:request('DELETE', {endpoints.channels, self.channelId, 'messages', self.id})
end

function Message:acknowledge()
	self.client:request('POST', {endpoints.channels, self.channelId, 'messages', self.id, 'ack'}, {})
end

return Message
