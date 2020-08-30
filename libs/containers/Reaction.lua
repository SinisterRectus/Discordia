local Container = require('./Container')
local User = require('./User')

local class = require('../class')
local typing = require('../typing')
local enums = require('../enums')

local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger

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
	return self.messageId == other.messageId and self.emojiHash == other.emojiHash
end

function Reaction:getUsers(limit, whence, userId)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(userId)
	end
	local data, err = self.client.api:getReactions(self.channelId, self.messageId, self.emojiHash, query)
	if data then
		for i, v in ipairs(data) do
			data[i] = User(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Reaction:delete(userId)
	local data, err
	if userId then
		data, err = self.client.api:deleteUserReaction(self.channelId, self.messageId, self.emojiHash, checkSnowflake(userId))
	else
		data, err = self.client.api:deleteOwnReaction(self.channelId, self.messageId, self.emojiHash)
	end
	if data then
		return true
	else
		return false, err
	end
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

function get:emojiMame()
	return self._emoji_name
end

function get:emojiHash()
	if self.emojiId then
		return self.emojiName .. ':' .. self.emojiId
	else
		return self.emojiName
	end
end

return Reaction
