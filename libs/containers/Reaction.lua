local Container = require('./Container')
local PartialEmoji = require('../structs/PartialEmoji')

local class = require('../class')

local Reaction, get = class('Reaction', Container)

function Reaction:__init(data, client)
	Container.__init(self, client)
	self._channel_id = assert(data.channel_id)
	self._message_id = assert(data.message_id)
	self._count = data.count
	self._me = data.me
	self._emoji = PartialEmoji(data.emoji, client)
end

function Reaction:__eq(other)
	return self.messageId == other.messageId and self.hash == other.hash
end

function Reaction:toString()
	return self.messageId .. ':' .. self.hash
end

function Reaction:getChannel()
	return self.client:getChannel(self.channelId)
end

function Reaction:getMessage()
	return self.client:getMessage(self.messageId)
end

function Reaction:getUsers(limit, whence, userId)
	return self.client:getReactionUsers(self.channelId, self.messageId, self.emoji.hash, limit, whence, userId)
end

function Reaction:delete(userId)
	return self.client:removeReaction(self.channelId, self.messageId, self.emoji.hash, userId)
end

function get:me()
	return self._me
end

function get:count()
	return self._count
end

function get:channelId()
	return self._channel_id
end

function get:messageId()
	return self._message_id
end

function get:hash()
	return self.emoji.id or self.emoji.name
end

return Reaction
