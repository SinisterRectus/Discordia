local Snowflake = require('./Snowflake')
local Bitfield = require('../utils/Bitfield')
local Embed = require('../structs/Embed')
local Attachment = require('../structs/Attachment')
local Mention = require('../structs/Mention')
local MessageActivity = require('../structs/MessageActivity')

local json = require('json')
local enums = require('../enums')
local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')
local constants = require('../constants')

local format = string.format
local insert = table.insert
local checkEnum = typing.checkEnum

local JUMP_LINK_FMT = constants.JUMP_LINK_FMT
local USER_PATTERN = constants.USER_PATTERN
local ROLE_PATTERN = constants.ROLE_PATTERN
local CHANNEL_PATTERN = constants.CHANNEL_PATTERN
local EMOJI_PATTERN = constants.EMOJI_PATTERN
local TIMESTAMP_PATTERN = constants.TIMESTAMP_PATTERN
local STYLED_TIMESTAMP_PATTERN = constants.STYLED_TIMESTAMP_PATTERN

local Message, get = class('Message', Snowflake)

function Message:__init(data, client)

	Snowflake.__init(self, data, client)

	self._channel_id = data.channel_id
	self._guild_id = data.guild_id
	self._webhook_id = data.webhook_id
	self._type = data.type
	self._author = client.state:newUser(data.author)
	self._content = data.content
	self._timestamp = data.timestamp
	self._edited_timestamp = data.edited_timestamp
	self._tts = data.tts
	self._mention_everyone = data.mention_everyone
	self._nonce = data.nonce
	self._pinned = data.pinned
	self._flags = data.flags

	self._embeds = helpers.structs(Embed, data.embeds)
	self._attachments = helpers.structs(Attachment, data.attachments)

	self._mentions = data.mentions and client.state:newUsers(data.mentions)
	self._reactions = data.reactions and client.state:newReactions(data.channel_id, data.id, data.reactions)
	self._referenced_message = data.referenced_message and client.state:newMessage(data.referenced_message)

	self._activity = data.activity and MessageActivity(data.activity)

	-- TODO: application

end

function Message:modify(payload)
	return self.client:editMessage(self.channelId, self.id, payload)
end

function Message:setContent(content)
	return self.client:editMessage(self.channelId, self.id, {content = content or json.null})
end

function Message:setEmbed(embed)
	return self.client:editMessage(self.channelId, self.id, {embed = embed or json.null})
end

function Message:hideEmbeds()
	local flags = Bitfield(self.flags)
	flags:disableValue(enums.messageFlag.suppressEmbeds)
	return self.client:editMessage(self.channelId, self.id, {flags = flags:toDec()})
end

function Message:showEmbeds()
	local flags = Bitfield(self.flags)
	flags:enableValue(enums.messageFlag.suppressEmbeds)
	return self.client:editMessage(self.channelId, self.id, {flags = flags:toDec()})
end

function Message:hasFlag(flag)
	return Bitfield(self.flags):hasValue(checkEnum(enums.messageFlag, flag))
end

function Message:pin()
	return self.client:pinMessage(self.channelId, self.id)
end

function Message:unpin()
	return self.client:unpinMessage(self.channelId, self.id)
end

function Message:addReaction(emoji)
	return self.client:addReaction(self.channelId, self.id, emoji)
end

function Message:removeReaction(emoji, userId)
	return self.client:removeReaction(self.channelId, self.id, emoji, userId)
end

function Message:clearReactions(emoji)
	return self.client:clearReactions(self.channel, self.id, emoji)
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

function Message:getMentions()

	local mentions = {}

	for str in self.content:gmatch('%b<>') do

		do local id = str:match(USER_PATTERN)
			if id then
				insert(mentions, {
					id = id,
					type = enums.mentionType.user,
					raw = str,
				})
				goto continue
			end
		end

		do local id = str:match(ROLE_PATTERN)
			if id then
				insert(mentions, {
					id = id,
					type = enums.mentionType.role,
					raw = str,
				})
				goto continue
			end
		end

		do local id = str:match(CHANNEL_PATTERN)
			if id then
				insert(mentions, {
					id = id,
					type = enums.mentionType.channel,
					raw = str,
				})
				goto continue
			end
		end

		do local a, name, id = str:match(EMOJI_PATTERN)
			if id then
				insert(mentions, {
					animated = a == 'a',
					name = name,
					id = id,
					type = enums.mentionType.emoji,
					raw = str,
				})
				goto continue
			end
		end

		do local timestamp = str:match(TIMESTAMP_PATTERN)
			if timestamp then
				insert(mentions, {
					timestamp = timestamp,
					type = enums.mentionType.timestamp,
				})
				goto continue
			end
		end

		do local timestamp, style = str:match(STYLED_TIMESTAMP_PATTERN)
			if timestamp then
				insert(mentions, {
					timestamp = timestamp,
					style = style,
					type = enums.mentionType.timestamp,
					raw = str,
				})
				goto continue
			end
		end

		::continue::

	end

	return helpers.structs(Mention, mentions)

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

function get:flags()
	return self._flags or 0
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

function get:mentionedUsers()
	return self._mentions
end

function get:embed()
	return self._embeds and self._embeds:get(1)
end

function get:attachment()
	return self._attachments and self._attachments:get(1)
end

function get:embeds()
	return self._embeds
end

function get:attachments()
	return self._attachments
end

function get:reactions()
	return self._reactions
end

function get:referencedMessage()
	return self._referenced_message
end

function get:activity()
	return self._activity
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
