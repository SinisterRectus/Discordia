local Snowflake = require('./Snowflake')
local User = require('./User')

local json = require('json')
local enums = require('../enums')
local class = require('../class')
local typing = require('../typing')
local constants = require('../constants')

local format = string.format
local insert = table.insert
local bor, band, bnot = bit.bor, bit.band, bit.bnot
local checkEnum = typing.checkEnum

local JUMP_LINK_FMT = constants.JUMP_LINK_FMT
local USER_PATTERN = constants.USER_PATTERN
local ROLE_PATTERN = constants.ROLE_PATTERN
local CHANNEL_PATTERN = constants.CHANNEL_PATTERN
local EMOJI_PATTERN = constants.EMOJI_PATTERN

local Message, get = class('Message', Snowflake)

local function parseMentionIds(content, pattern)
	local ids, seen = {}, {}
	for id in content:gmatch(pattern) do
		if not seen[id] then
			insert(ids, id)
			seen[id] = true
		end
	end
	return ids
end

local function parseMentions(content, pattern, objects)
	local hashed = {} -- NOTE: avoid re-hashing in the future
	for _, v in pairs(objects) do
		hashed[v.id] = v
	end
	local mentions = {}
	for id in content:gmatch(pattern) do
		if hashed[id] then
			insert(mentions, hashed[id])
			hashed[id] = nil
		end
	end
	return mentions
end

function Message:__init(data, client)
	Snowflake.__init(self, data, client)
	self._channel_id = data.channel_id
	self._guild_id = data.guild_id
	self._webhook_id = data.webhook_id
	return self:_load(data)
end

function Message:_load(data)
	self._type = data.type
	self._author = User(data.author, self.client)
	self._content = data.content
	self._timestamp = data.timestamp
	self._edited_timestamp = data.edited_timestamp
	self._tts = data.tts
	self._mention_everyone = data.mention_everyone
	self._nonce = data.nonce
	self._pinned = data.pinned
	self._flags = data.flags
	for i, v in ipairs(data.mentions) do
		data.mentions[i] = User(v, self.client)
	end
	self._mentions = data.mentions
	self._embeds = data.embeds
	self._attachments = data.attachments
	-- TODO: process members on MESSAGE_CREATE
	-- TODO: reactions, activity, application, reference
end

function Message:setContent(content)
	return self.client:editMessage(self.channelId, self.id, {content = content or json.null})
end

function Message:setEmbed(embed)
	return self.client:editMessage(self.channelId, self.id, {embed = embed or json.null})
end

function Message:hideEmbeds()
	local flags = bor(self.flags, enums.messageFlag.suppressEmbeds)
	return self.client:editMessage({flags = flags})
end

function Message:showEmbeds()
	local flags = band(self.flags, bnot(enums.messageFlag.suppressEmbeds))
	return self.client:editMessage({flags = flags})
end

function Message:hasFlag(flag)
	flag = checkEnum(enums.messageFlag, flag)
	return band(self.flags, flag) == flag
end

function Message:pin()
	return self.client:pinMessage(self.channelId, self.id)
end

function Message:unpin()
	return self.client:unpinMessage(self.channelId, self.id)
end

function Message:addReaction(emojiHash)
	return self.client:addReaction(self.channelId, self.id, emojiHash)
end

function Message:removeReaction(emojiHash, userId)
	return self.client:removeReaction(self.channelId, self.id, emojiHash, userId)
end

function Message:clearAllReactions(emojiHash)
	return self.client:clearAllReactions(self.channel, self.id, emojiHash)
end

function Message:delete()
	return self.client:deleteMessage(self.channelId, self.id)
end

function Message:reply(payload)
	return self.client:createMessage(self.channelId, payload)
end

function Message:getChannel()
	return self.client:getChannel(self.channelId)
end

function Message:getMentionedUserIds()
	return parseMentionIds(self.content, USER_PATTERN)
end

function Message:getMentionedRoleIds()
	return parseMentionIds(self.content, ROLE_PATTERN)
end

function Message:getMentionedChannelIds()
	return parseMentionIds(self.content, CHANNEL_PATTERN)
end

function Message:getMentionedEmojiIds()
	return parseMentionIds(self.content, EMOJI_PATTERN)
end

function Message:getMentionedUsers()
	return parseMentions(self.content, USER_PATTERN, self._mentions)
end

function Message:getMentionedRoles()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local roles, err = self.client:getGuildRoles(self.guildId)
	if roles then
		return parseMentions(self.content, ROLE_PATTERN, roles)
	else
		return nil, err
	end
end

function Message:getMentionedChannels()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local channels, err = self.client:getGuildChannels(self.guildId)
	if channels then
		return parseMentions(self.content, CHANNEL_PATTERN, channels)
	else
		return nil, err
	end
end

function Message:getMentionedEmojis()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local emojis, err = self.client:getGuildEmojis(self.guildId)
	if emojis then
		return parseMentions(self.content, EMOJI_PATTERN, emojis)
	else
		return nil, err
	end
end

function Message:crosspost()
	return self.client:crosspostMessage(self.channelId, self.id)
end

function Message:getMember()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	return self.client:getGuildMember(self.guildId, self.author.id)
end

function Message:getGuild()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	return self.client:getGuild(self.guildId)
end

function get:type()
	return self._type
end

function get:pinned()
	return self._pinned
end

function get:tts()
	return self._tts
end

function get:nonce()
	return self._nonce
end

function get:author()
	return self._author
end

function get:editedTimestamp()
	return self._edited_timestamp
end

function get:mentionsEveryone()
	return self._mention_everyone
end

function get:embed()
	return self._embeds[1] -- raw table
end

function get:attachment()
	return self._attachments[1] -- raw table
end

function get:embeds()
	return self._embeds -- raw table
end

function get:attachments()
	return self._attachments -- raw table
end

function get:content()
	return self._content
end

function get:channelId()
	return self._channel_id
end

function get:guildId()
	return self._guild_id
end

function get:link()
	local guildId = self.guildId
	local channelId = self.channelId
	return format(JUMP_LINK_FMT, guildId or '@me', channelId, self.id)
end

function get:webhookId()
	return self._webhook_id
end

return Message
