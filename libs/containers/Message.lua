local json = require('json')
local constants = require('constants')
local Cache = require('iterables/Cache')
local ArrayIterable = require('iterables/ArrayIterable')
local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')
local Resolver = require('client/Resolver')

local insert, remove = table.insert, table.remove

local Message, get = require('class')('Message', Snowflake)

--[[
@class Message x Snowflake

Represents a text message sent in a Discord text channel. Messages can contain
simple content strings, rich embeds, attachments, or reactions.
]]
function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:_insert(data.author)
	self._timestamp = nil -- waste of space; can be calculated from Snowflake ID
	if data.reactions and #data.reactions > 0 then
		self._reactions = Cache(data.reactions, Reaction, self)
	end
	return self:_loadMore(data)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

local function parseUserMentions(mentions, cache)
	if #mentions == 0 then return end
	for i, user in ipairs(mentions) do
		mentions[i] =  cache:_insert(user)
	end
	return mentions
end

local function parseChannelMentions(content)
	if not content:find('<#') then return end
	local ids, seen = {}, {}
	for id in content:gmatch('<#(%d-)>') do
		if not seen[id] then
			insert(ids, id)
			seen[id] = true
		end
	end
	return ids
end

function Message:_loadMore(data)

	if data.mentions then
		local mentions = parseUserMentions(data.mentions, self.client._users)
		if self._mentioned_users then
			self._mentioned_users._array = mentions
		else
			self._mentioned_users_raw = mentions
		end
	end

	if data.mention_roles then
		local mentions = #data.mention_roles > 0 and data.mention_roles or nil
		if self._mentioned_roles then
			self._mentioned_roles._array = mentions
		else
			self._mentioned_roles_raw = mentions
		end
	end

	if data.content then
		if self._mentioned_channels then
			self._mentioned_channels._array = parseChannelMentions(data.content)
		end
		self._clean_content = nil
	end

	if data.embeds then
		self._embeds = #data.embeds > 0 and data.embeds or nil
	end

	if data.attachments then
		self._attachments = #data.attachments > 0 and data.attachments or nil
	end

end

function Message:_addReaction(d)

	local reactions = self._reactions

	if not reactions then
		reactions = Cache({}, Reaction, self)
		self._reactions = reactions
	end

	local emoji = d.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	if reaction then
		reaction._count = reaction._count + 1
		if d.user_id == self.client._user._id then
			reaction._me = true
		end
	else
		d.me = d.user_id == self.client._user._id
		d.count = 1
		reaction = reactions:_insert(d)
	end
	return reaction

end

function Message:_removeReaction(d)

	local reactions = self._reactions

	local emoji = d.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	reaction._count = reaction._count - 1
	if d.user_id == self.client._user._id then
		reaction._me = false
	end

	if reaction._count == 0 then
		reactions:_delete(k)
	end

	return reaction

end

function Message:_setOldContent(d)

	if not d.edited_timestamp then return end
	if self._content == d.content then return end
	if self._edited and self._edited[d.edited_timestamp] then return end

	if self._old then
		local t = type(self._old)
		if t == 'string' then
			self._old = {self._old, self._content}
		elseif t == 'table' then
			insert(self._old, self._content)
		end
		self._edited[d.edited_timestamp] = true
	else
		self._old = self._content
		self._edited = {[d.edited_timestamp] = true}
	end

end

function Message:_getOldContent(d)

	if not d.edited_timestamp then return end
	if not self._old then return end

	local t = type(self._old)

	if t == 'string' then
		local old = self._old
		self._old = nil
		self._edited = nil
		return old
	elseif t == 'table' then
		local old = remove(self._old, 1)
		if #self._old == 0 then
			self._old = nil
			self._edited = nil
		end
		return old
	end

end

function Message:_modify(payload)
	local data, err = self.client._api:editMessage(self._parent._id, self._id, payload)
	if data then
		self:_setOldContent(data)
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[[
@method setContent
@tags http
@param content: string
@ret boolean

Sets the message's content. The message must be authored by the current user
(ie: you cannot change the content of messages sent by other users). The content
must be from 1 to 2000 characters in length.
]]
function Message:setContent(content)
	return self:_modify({content = content or json.null})
end

--[[
@method setEmbed
@tags http
@param embed: table
@ret boolean

Sets the message's embed. The message must be authored by the current user.
(ie: you cannot change the embed of messages sent by other users).
]]
function Message:setEmbed(embed)
	return self:_modify({embed = embed or json.null})
end

--[[
@method pin
@tags http
@ret boolean

Pins the message in the channel.
]]
function Message:pin()
	local data, err = self.client._api:addPinnedChannelMessage(self._parent._id, self._id)
	if data then
		self._pinned = true
		return true
	else
		return false, err
	end
end

--[[
@method unpin
@tags http
@ret boolean

Unpins the message in the channel.
]]
function Message:unpin()
	local data, err = self.client._api:deletePinnedChannelMessage(self._parent._id, self._id)
	if data then
		self._pinned = false
		return true
	else
		return false, err
	end
end

--[[
@method removeReaction
@tags http
@param emoji Emoji Resolveable
@ret boolean

Adds a reaction to the message. Note that this does not return the new reaction
object; wait for the `reactionAdd` event instead.
]]
function Message:addReaction(emoji)
	emoji = Resolver.emoji(emoji)
	local data, err = self.client._api:createReaction(self._parent._id, self._id, emoji)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method removeReaction
@tags http
@param emoji Emoji Resolveable
@param [id]: User ID Resolveable
@ret boolean

Removes a reaction from the message. Note that this does not return the old
reaction object; wait for the `reactionAdd` event instead. If no user is
indicated, then this will remove the current user's reaction.
]]
function Message:removeReaction(emoji, id)
	emoji = Resolver.emoji(emoji)
	local data, err
	if id then
		id = Resolver.userId(id)
		data, err = self.client._api:deleteUserReaction(self._parent._id, self._id, emoji, id)
	else
		data, err = self.client._api:deleteOwnReaction(self._parent._id, self._id, emoji)
	end
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method clearReactions
@tags http
@ret boolean

Removes all reactions from the message.
]]
function Message:clearReactions()
	local data, err = self.client._api:deleteAllReactions(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method delete
@tags http
@ret boolean

Permanently deletes the message. This cannot be undone!
]]
function Message:delete()
	local data, err = self.client._api:deleteMessage(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method reply
@tags http
@param content: string|table
@ret Message

Equivalent to `$.channel:send(content)`.
]]
function Message:reply(content)
	return self._parent:send(content)
end

--[[
@property reactions: Cache

An iterable cache of all reactions that exist for this message.
]]
function get.reactions(self)
	if not self._reactions then
		self._reactions = Cache({}, Reaction, self)
	end
	return self._reactions
end

--[[
@property mentionedUsers: ArrayIterable

An iterable array of all users that are mentioned in this message.  Object order
is not guaranteed.
]]
function get.mentionedUsers(self)
	if not self._mentioned_users then
		self._mentioned_users = ArrayIterable(self._mentioned_users_raw)
		self._mentioned_users_raw = nil
	end
	return self._mentioned_users
end

--[[
@property mentionedRoles: ArrayIterable

An iterable array of known roles that are mentioned in this message, excluding
the default everyone role. The message must be in a guild text channel and the
roles must be cached in that channel's guild for them to appear here. Object
order is not guaranteed.
]]
function get.mentionedRoles(self)
	if not self._mentioned_roles then
		local guild = self.guild
		local roles = guild and guild._roles
		self._mentioned_roles = ArrayIterable(self._mentioned_roles_raw, function(id)
			return roles:get(id)
		end)
		self._mentioned_roles_raw = nil
	end
	return self._mentioned_roles
end

--[[
@property mentionedChannels: ArrayIterable

An iterable array of all known channels that are mentioned in this message. If
the client does not have the channel cached, then it will not appear here.
Object order is not guaranteed.
]]
function get.mentionedChannels(self)
	if not self._mentioned_channels then
		local ids = parseChannelMentions(self._content)
		local client = self.client
		self._mentioned_channels = ArrayIterable(ids, function(id)
			local guild = client._channel_map[id]
			if guild then
				return guild._text_channels:get(id) or guild._voice_channels:get(id)
			else
				return client._private_channels:get(id) or client._group_channels:get(id)
			end
		end)
	end
	return self._mentioned_channels
end

local usersMeta = {__index = function(_, k) return '@' .. k end}
local rolesMeta = {__index = function(_, k) return '@' .. k end}
local channelsMeta = {__index = function(_, k) return '#' .. k end}
local everyone = '@' .. constants.ZWSP .. 'everyone'
local here = '@' .. constants.ZWSP .. 'here'

--[[
@property cleanContent: string

The message content with all recognized mentions replaced by names and with
@everyone and @here mentions escaped by a zero-width space (ZWSP).
]]
function get.cleanContent(self)

	if not self._clean_content then

		local content = self._content
		local guild = self.guild

		local users = setmetatable({}, usersMeta)
		for user in self.mentionedUsers:iter() do
			local member = guild and guild._members:get(user._id)
			users[user._id] = '@' .. (member and member._nick or user._username)
		end

		local roles = setmetatable({}, rolesMeta)
		for role in self.mentionedRoles:iter() do
			roles[role._id] = '@' .. role._name
		end

		local channels = setmetatable({}, channelsMeta)
		for channel in self.mentionedChannels:iter() do
			channels[channel._id] = '#' .. channel._name
		end

		self._clean_content = content
			:gsub('<@!?(%d+)>', users)
			:gsub('<@&(%d+)>', roles)
			:gsub('<#(%d+)>', channels)
			:gsub('@everyone', everyone)
			:gsub('@here', here)

	end

	return self._clean_content

end

--[[
@property mentionsEveryone: boolean

Whether this message mentions @everyone or @here.
]]
function get.mentionsEveryone(self)
	return self._mention_everyone
end

--[[
@property pinned: boolean

Whether this message belongs to its channel's pinned messages.
]]
function get.pinned(self)
	return self._pinned
end

--[[
@property tts: boolean

Whether this message is a text-to-speech message.
]]
function get.tts(self)
	return self._tts
end

--[[
@property nonce: string|number|boolean|nil

Used by the official Discord client to detect the success of a sent message.
]]
function get.nonce(self)
	return self._nonce
end

--[[
@property editedTimestamp: string|nil

The date and time at which the message was most recently edited, represented as
an ISO 8601 string plus microseconds when available.
]]
function get.editedTimestamp(self)
	return self._edited_timestamp
end

--[[
@property content: string

The raw message content. This should be between 0 and 2000 characters in length.
]]
function get.content(self)
	return self._content
end

--[[
@property author: User

The object of the user that created the message.
]]
function get.author(self)
	return self._author
end

--[[
@property channel: TextChannel

The channel in which this message was sent. Equivalent to `$.parent`.
]]
function get.channel(self)
	return self._parent
end

--[[
@property type: number

The message type. Use the `messageType` enumeration for a human-readable
representation.
]]
function get.type(self)
	return self._type
end

--[[
@property embed: table|nil

A raw data table that represents the first rich embed that exists in this
message. See the Discord documentation for more information.
]]
function get.embed(self)
	return self._embeds and self._embeds[1]
end

--[[
@property attachment: table|nil

A raw data table that represents the first file attachment that exists in this
message. See the Discord documentation for more information.
]]
function get.attachment(self)
	return self._attachments and self._attachments[1]
end

--[[
@property embeds: table|nil

A raw data table that contains all embeds that exist for this message. If
there are none, this table will not be present.
]]
function get.embeds(self)
	return self._embeds
end

--[[
@property attachments: table|nil

A raw data table that contains all attachments that exist for this message. If
there are none, this table will not be present.
]]
function get.attachments(self)
	return self._attachments
end

--[[
@property guild: Guild|nil

The guild in which this message was sent. This will not exist if the message
was not sent in a guild text channel. Equivalent to `$.channel.guild`.
]]
function get.guild(self)
	return self._parent.guild
end

--[[
@property member: Member|nil

The member object of the message's author. This will not exist if the message
is not sent in a guild text channel or if the member object is not cached.
Equivalent to `$.guild.members:get($.author.id)`.
]]
function get.member(self)
	local guild = self.guild
	return guild and guild._members:get(self._author._id)
end

return Message
