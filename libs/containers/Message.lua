local Snowflake = require('./Snowflake')
local Channel = require('./Channel')
local Member = require('./Member')
local Role = require('./Role')
local User = require('./User')

local class = require('../class')
local typing = require('../typing')

local format = string.format
local insert = table.insert
local checkSnowflake = typing.checkSnowflake
local LINK_FMT = "https://discord.com/channels/%s/%s/%s"

local USER_PATTERN = '<@!?(%d+)>'
local ROLE_PATTERN = '<@&(%d+)>'
local CHANNEL_PATTERN = '<#(%d+)>'
local EMOJI_PATTERN = '<a?:[%w_]+:(%d+)>'

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

local function parseMentions(content, pattern, constructor, data, client)
	local hashed = {}
	for _, v in ipairs(data) do
		hashed[v.id] = v
	end
	local mentions = {}
	for id in content:gmatch(pattern) do
		if hashed[id] then
			insert(mentions, constructor(hashed[id], client))
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
	self._mentions = data.mentions
	self._embeds = data.embeds
	self._attachments = data.attachments
	-- TODO: process members on MESSAGE_CREATE
	-- TODO: reactions, activity, application, reference
end

function Message:addReaction(emojiHash)
	local data, err = self.client.api:createReaction(self.channelId, self.id, emojiHash)
	if data then
		return true
	else
		return false, err
	end
end

function Message:removeReaction(emojiHash, userId)
	local data, err
	if userId then
		data, err = self.client.api:deleteUserReaction(self.channelId, self.id, emojiHash, checkSnowflake(userId))
	else
		data, err = self.client.api:deleteOwnReaction(self.channelId, self.id, emojiHash)
	end
	if data then
		return true
	else
		return false, err
	end
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
	return parseMentions(self.content, USER_PATTERN, User, self._mentions, self.client)
end

function Message:getMentionedRoles()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local data, err = self.client.api:getGuildRoles(self.guildId)
	if data then
		return parseMentions(self.content, ROLE_PATTERN, Role, data, self.client)
	else
		return nil, err
	end
end

function Message:getMentionedChannels()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local data, err = self.client.api:getGuildChannels(self.guildId)
	if data then
		return parseMentions(self.content, CHANNEL_PATTERN, Channel, data, self.client)
	else
		return nil, err
	end
end

function Message:getMentionedEmojis()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local data, err = self.client.api:getGuildEmojis(self.guildId)
	if data then
		return parseMentions(self.content, EMOJI_PATTERN, Channel, data, self.client)
	else
		return nil, err
	end
end

function Message:getMember()
	if not self.guildId then
		return nil, 'Not a guild message'
	end
	local data, err = self.client.api:getGuildMember(self.id, self.author.id)
	if data then
		data.guild_id = self.id
		return Member(data, self)
	else
		return nil, err
	end
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

function get.link(self)
	local guildId = self.guildId
	local channelId = self.channelId
	return format(LINK_FMT, guildId or '@me', channelId, self.id)
end

function get:webhookId()
	return self._webhook_id
end

return Message
