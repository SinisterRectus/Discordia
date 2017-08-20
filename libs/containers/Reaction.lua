local Container = require('containers/abstract/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local Reaction, get = require('class')('Reaction', Container)

--[[
@class Reaction x Container

Represents an emoji that has been used to react to a Discord text message. Both
standard and custom emojis can be used.
]]
function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	self._emoji_id = data.emoji.id
	self._emoji_name = data.emoji.name
end

function Reaction:__hash()
	return self._emoji_id or self._emoji_name
end

--[[
@method getUsers
@tags http
@ret SecondaryCache

Returns a newly constructed cache of all users that have used this reaction in
its parent message. The cache is not automatically updated via gateway events,
but the internally referenced user objects may be updated. You must call this
method again to guarantee that the objects are update to date.
]]
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

--[[
@method delete
@tags http
@param id: User ID Resolveable
@ret boolean

Equivalent to `$.message:removeReaction($)`
]]
function Reaction:delete(id)
	return self._parent:removeReaction(self, id)
end

--[[
@property emojiId: string|nil

The ID of the emoji used in this reaction if it is a custom emoji.
]]
function get.emojiId(self)
	return self._emoji_id
end

--[[
@property emojiName: string

The name of the emoji used in this reaction if it is a custom emoji. Otherwise,
this will be the raw string for a standard emoji.
]]
function get.emojiName(self)
	return self._emoji_name
end

--[[
@property emojiURL: string|nil

The URL that can be used to view a full version of the emoji used in this
reaction if it is a custom emoji.
]]
function get.emojiURL(self)
	local id = self._emoji_id
	return id and format('https://cdn.discordapp.com/emojis/%s.png', id) or nil
end

--[[
@property me: boolean

Whether the current user has used this reaction.
]]
function get.me(self)
	return self._me
end

--[[
@property count: number

The total number of users that have used this reaction.
]]
function get.count(self)
	return self._count
end

--[[
@property message: Message

The message on which this reaction exists.
]]
function get.message(self)
	return self._parent
end

return Reaction
