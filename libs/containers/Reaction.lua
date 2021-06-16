local Container = require('./Container')

local class = require('../class')
local typing = require('../typing')

local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize

local Reaction, get = class('Reaction', Container)

function Reaction:__init(data, client)
	Container.__init(self, client)
	self._channel_id = assert(data.channel_id)
	self._message_id = assert(data.message_id)
	self._count = data.count
	self._me = data.me
	self._emoji_id = data.emoji.id
	self._emoji_name = data.emoji.name
end

function Reaction:__eq(other)
	return self.messageId == other.messageId and self.hash == other.hash
end

function Reaction:getChannel()
	return self.client:getChannel(self.channelId)
end

function Reaction:getMessage()
	return self.client:getMessage(self.messageId)
end

function Reaction:getUsers(limit, whence, userId)
	return self.client:getReactionUsers(self.channelId, self.messageId, self.emojiHash, limit, whence, userId)
end

function Reaction:getEmojiURL(ext, size)
	if not self.emojiId then
		return nil, 'Cannot provide URL for default emoji'
	end
	ext = ext and checkImageExtension(ext)
	size = size and checkImageSize(size)
	return self.client.cdn:getCustomEmojiURL(self.emojiId, ext, size)
end

function Reaction:delete(userId)
	return self.client:removeReaction(self.channelId, self.messageId, self.emojiHash, userId)
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

function get:emojiId()
	return self._emoji_id
end

function get:emojiName()
	return self._emoji_name
end

function get:emojiHash()
	if self.emojiId then
		return self.emojiName .. ':' .. self.emojiId
	else
		return self.emojiName
	end
end

function get:hash()
	return self.emojiId or self.emojiName
end

return Reaction
