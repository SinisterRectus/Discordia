local json = require('json')
local Container = require('containers/abstract/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local null = json.null
local format = string.format

local Reaction, get = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	self._emoji_id = data.emoji.id ~= null and data.emoji.id or nil
	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id or self._emoji_name
end

local function getUsers(self, query)
	local emoji = Resolver.emoji(self)
	local message = self._parent
	local channel = message._parent
	local data, err = self.client._api:getReactions(channel._id, message._id, emoji, query)
	if data then
		return SecondaryCache(data, self.client._users)
	else
		return nil, err
	end
end

function Reaction:getUsers(limit)
	return getUsers(self, limit and {limit = limit})
end

function Reaction:getUsersBefore(id, limit)
	id = Resolver.userId(id)
	return getUsers(self, {before = id, limit = limit})
end

function Reaction:getUsersAfter(id, limit)
	id = Resolver.userId(id)
	return getUsers(self, {after = id, limit = limit})
end

function Reaction:delete(id)
	return self._parent:removeReaction(self, id)
end

function get.emojiId(self)
	return self._emoji_id
end

function get.emojiName(self)
	return self._emoji_name
end

function get.emojiHash(self)
	if self._emoji_id then
		return self._emoji_name .. ':' .. self._emoji_id
	else
		return self._emoji_name
	end
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
