--[=[
@c Reaction x Container
@d Represents an emoji that has been used to react to a Discord text message. Both
standard and custom emojis can be used.
]=]

local json = require('json')
local Container = require('containers/abstract/Container')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local null = json.null
local format = string.format

local Reaction, get = require('class')('Reaction', Container)

function Reaction:__init(data, parent)
	Container.__init(self, data, parent)
	local emoji = data.emoji
	self._emoji_id = emoji.id ~= null and emoji.id or nil
	self._emoji_name = emoji.name
	if emoji.animated ~= null and emoji.animated ~= nil then -- not always present
		self._emoji_animated = emoji.animated
	end
end

--[=[
@m __hash
@r string
@d Returns `Reaction.emojiId or Reaction.emojiName`
]=]
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

--[=[
@m getUsers
@t http
@op limit number
@r SecondaryCache
@d Returns a newly constructed cache of all users that have used this reaction in
its parent message. The cache is not automatically updated via gateway events,
but the internally referenced user objects may be updated. You must call this
method again to guarantee that the objects are update to date.
]=]
function Reaction:getUsers(limit)
	return getUsers(self, limit and {limit = limit})
end

--[=[
@m getUsersBefore
@t http
@p id User-ID-Resolvable
@op limit number
@r SecondaryCache
@d Returns a newly constructed cache of all users that have used this reaction before the specified id in
its parent message. The cache is not automatically updated via gateway events,
but the internally referenced user objects may be updated. You must call this
method again to guarantee that the objects are update to date.
]=]
function Reaction:getUsersBefore(id, limit)
	id = Resolver.userId(id)
	return getUsers(self, {before = id, limit = limit})
end

--[=[
@m getUsersAfter
@t http
@p id User-ID-Resolvable
@op limit number
@r SecondaryCache
@d Returns a newly constructed cache of all users that have used this reaction
after the specified id in its parent message. The cache is not automatically
updated via gateway events, but the internally referenced user objects may be
updated. You must call this method again to guarantee that the objects are update to date.
]=]
function Reaction:getUsersAfter(id, limit)
	id = Resolver.userId(id)
	return getUsers(self, {after = id, limit = limit})
end

--[=[
@m delete
@t http
@op id User-ID-Resolvable
@r boolean
@d Equivalent to `Reaction.message:removeReaction(Reaction)`
]=]
function Reaction:delete(id)
	return self._parent:removeReaction(self, id)
end

--[=[@p emojiId string/nil The ID of the emoji used in this reaction if it is a custom emoji.]=]
function get.emojiId(self)
	return self._emoji_id
end

--[=[@p emojiName string The name of the emoji used in this reaction.
This will be the raw string for a standard emoji.]=]
function get.emojiName(self)
	return self._emoji_name
end

--[=[@p emojiHash string The discord hash for the emoji used in this reaction.
This will be the raw string for a standard emoji.]=]
function get.emojiHash(self)
	if self._emoji_id then
		return self._emoji_name .. ':' .. self._emoji_id
	else
		return self._emoji_name
	end
end

--[=[@p emojiURL string/nil string The URL that can be used to view a full
version of the emoji used in this reaction if it is a custom emoji.]=]
function get.emojiURL(self)
	local id = self._emoji_id
	local ext = self._emoji_animated and 'gif' or 'png'
	return id and format('https://cdn.discordapp.com/emojis/%s.%s', id, ext) or nil
end

--[=[@p me boolean Whether the current user has used this reaction.]=]
function get.me(self)
	return self._me
end

--[=[@p count number The total number of users that have used this reaction.]=]
function get.count(self)
	return self._count
end

--[=[@p message Message The message on which this reaction exists.]=]
function get.message(self)
	return self._parent
end

return Reaction
