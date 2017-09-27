local json = require('json')
local Container = require('containers/abstract/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local null = json.null
local format = string.format

local Reaction, get = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)

	-- The JSON decoder treats `null` as an empty table. If we have an empty table here it
	-- is due to `null` being the emoji ID (therefor is a unicode emoji). Don't set the emojiID
	if not( type( data.emoji.id ) == "table" and #data.emoji.id == 0 ) then
		self._emoji_id = type( data.emoji.id ) == "table" and #data.emoji.id == 0
	end

	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id ~= null and self._emoji_id or self._emoji_name
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

function Reaction:delete(id)
	return self._parent:removeReaction(self, id)
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
