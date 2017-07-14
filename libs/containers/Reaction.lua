local Container = require('utils/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local Reaction = require('class')('Reaction', Container)
local get = Reaction.__getters

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	self._emoji_id = data.emoji.id
	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id or self._emoji_name
end

function Reaction:getUsers()
	local emoji = Resolver.emoji(self)
	local message = self._parent
	local channel = message._parent
	local data, err = self.client._api:getReactions(channel._id, message._id, emoji)
	if data then
		return SecondaryCache(data, self.client._users)
	else
		return nil, err
	end
end

function Reaction:delete(user)
	local emoji = Resolver.emoji(self)
	local message = self._parent
	local channel = message._parent
	local data, err
	if user then
		user = Resolver.id(user)
		data, err = self.client._api:deleteUserReaction(channel._id, message._id, emoji, user)
	else
		data, err = self.client._api:deleteOwnReaction(channel._id, message._id, emoji)
	end
	if data then
		return true
	else
		return false, err
	end
end

function get.emojiId(self)
	return self._emoji_id
end

function get.emojiName(self)
	return self._emoji_name
end

function get.emojiURL(self)
	local id = self._emoji_id
	return id and format('https://cdn.discordapp.com/emojis/%s.png', id) or nil
end

function get.me(self)
	return self._me
end

function get.count(self)
	return self._count
end

function get.message(self)
	return self._parent
end

return Reaction
