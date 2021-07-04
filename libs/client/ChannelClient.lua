local enums = require('../enums')
local typing = require('../typing')
local messaging = require('../messaging')

local parseFiles = messaging.parseFiles
local parseEmbeds = messaging.parseEmbeds
local parseContent = messaging.parseContent
local parseAllowedMentions = messaging.parseAllowedMentions
local parseMessageReference = messaging.parseMessageReference
local checkPermissionOverwrites = messaging.checkPermissionOverwrites
local checkEmoji = messaging.checkEmoji
local checkBitfield = messaging.checkBitfield

local opt = typing.opt
local checkType = typing.checkType
local checkEnum = typing.checkEnum
local checkInteger = typing.checkInteger
local checkImageData = typing.checkImageData
local checkSnowflake = typing.checkSnowflake
local checkSnowflakeArray = typing.checkSnowflakeArray

local Client = {}

function Client:getChannel(channelId)
	channelId = checkSnowflake(channelId)
	local channel = self.state:getChannel(channelId)
	if channel then
		return channel
	end
	local data, err = self.api:getChannel(channelId)
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

function Client:modifyChannel(channelId, payload)
	channelId = checkSnowflake(channelId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyChannel(channelId, {
		name = opt(payload.name, checkType, 'string'),
		type = opt(payload.type, checkEnum, enums.channelType),
		topic = opt(payload.topic, checkType, 'string'),
		bitrate = opt(payload.bitrate, checkInteger),
		user_limit = opt(payload.userLimit, checkInteger),
		rate_limit_per_user = opt(payload.rateLimit, checkInteger),
		position = opt(payload.position, checkInteger),
		parent_id = opt(payload.parentId, checkInteger),
		nsfw = opt(payload.nsfw, checkType, 'boolean'),
		permission_overwrites = opt(payload.permissionOverwrites, checkPermissionOverwrites),
	})
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

function Client:editChannelPermissions(channelId, overwriteId, payload)
	channelId = checkSnowflake(channelId)
	overwriteId = checkSnowflake(overwriteId)
	local overwrite = { -- create a new object because 204 result
		type = checkEnum(enums.permissionOverwriteType, payload.type), -- must be included
		allow = checkBitfield(payload.allowedPermissions), -- must include original value if not changing
		deny = checkBitfield(payload.deniedPermissions), -- must include original value if not changing
	}
	local data, err = self.api:editChannelPermissions(channelId, overwriteId, overwrite)
	if data then -- 204
		overwrite.id = overwriteId -- inject the id
		return self.state:newOverwite(channelId, overwrite)
	else
		return false, err
	end
end

function Client:deleteChannelPermission(channelId, overwriteId)
	channelId = checkSnowflake(channelId)
	overwriteId = checkSnowflake(overwriteId)
	local data, err = self.api:deleteChannelPermission(channelId, overwriteId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:deleteChannel(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:deleteCloseChannel(channelId)
	if data then
		return true -- 200
	else
		return false, err
	end
end

function Client:createChannelInvite(channelId, payload)
	channelId = checkSnowflake(channelId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createChannelInvite(channelId, {
			max_age = opt(payload.maxAge, checkInteger),
			max_uses = opt(payload.maxUses, checkInteger),
			temporary = opt(payload.temporary, checkType, 'boolean'),
			unique = opt(payload.unique, checkType, 'boolean'),
		})
	else
		data, err = self.api:createChannelInvite(channelId)
	end
	if data then
		return self.state:newInvite(data)
	else
		return nil, err
	end
end

function Client:getChannelInvites(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelInvites(channelId)
	if data then
		return self.state:newInvites(data)
	else
		return nil, err
	end
end

function Client:createWebhook(channelId, payload)
	channelId = checkSnowflake(channelId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createWebhook(channelId, {
			name = opt(payload.name, checkType, 'string'),
			avatar = opt(payload.avatar, checkImageData),
		})
	else
		data, err = self.api:createWebhook(channelId, {name = checkType('string', payload)})
	end
	if data then
		return self.state:newWebhook(data)
	else
		return nil, err
	end
end

function Client:getChannelWebhooks(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelWebhooks(channelId)
	if data then
		return self.state:newWebooks(data)
	else
		return nil, err
	end
end

function Client:bulkDeleteMessages(channelId, messageIds)
	channelId = checkSnowflake(channelId)
	messageIds = checkSnowflakeArray(messageIds)
	local data, err
	if #messageIds == 1 then
		data, err = self.api:deleteMessage(channelId, messageIds[1])
	else
		data, err = self.api:bulkDeleteMessages(channelId, {messages = messageIds})
	end
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:getChannelMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:getChannelMessage(channelId, messageId)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:getChannelMessages(channelId, limit, whence, messageId)
	channelId = checkSnowflake(channelId)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(messageId)
	end
	local data, err = self.api:getChannelMessages(channelId, query)
	if data then
		return self.state:newMessages(data)
	else
		return nil, err
	end
end

function Client:getChannelFirstMessage(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelMessages(channelId, {after = channelId, limit = 1})
	if data then
		if data[1] then
			return self.state:newMessage(data[1])
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function Client:getChannelLastMessage(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelMessages(channelId, {limit = 1})
	if data then
		if data[1] then
			return self.state:newMessage(data[1])
		else
			return nil, 'Channel has no messages'
		end
	else
		return nil, err
	end
end

function Client:getPinnedMessages(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getPinnedMessages(channelId)
	if data then
		return self.state:newMessages(data)
	else
		return nil, err
	end
end

function Client:triggerTypingIndicator(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:triggerTypingIndicator(channelId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:createMessage(channelId, payload)
	channelId = checkSnowflake(channelId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createMessage(channelId, {
			content = parseContent(payload),
			tts = opt(payload.tts, checkType, 'boolean'),
			embeds = parseEmbeds(payload),
			message_reference = parseMessageReference(payload),
			allowed_mentions = parseAllowedMentions(payload, self.defaultAllowedMentions),
		}, nil, parseFiles(payload))
	else
		data, err = self.api:createMessage(channelId, {content = payload})
	end
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:editMessage(channelId, messageId, payload)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	payload = checkType('table', payload)
	local data, err = self.api:editMessage(channelId, messageId, {
		content = parseContent(payload),
		embeds = parseEmbeds(payload),
		flags = opt(payload.flags, checkInteger),
		allowed_mentions = parseAllowedMentions(payload, self.defaultAllowedMentions),
	}, nil, parseFiles(payload))
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:deleteMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:deleteMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:pinMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:pinMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:unpinMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:unpinMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:addReaction(channelId, messageId, emoji)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emoji = checkEmoji(emoji)
	local data, err = self.api:createReaction(channelId, messageId, emoji)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:removeReaction(channelId, messageId, emoji, userId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emoji = checkEmoji(emoji)
	local data, err
	if userId then
		userId = checkSnowflake(userId)
		data, err = self.api:deleteUserReaction(channelId, messageId, emoji, userId)
	else
		data, err = self.api:deleteOwnReaction(channelId, messageId, emoji)
	end
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:clearReactions(channelId, messageId, emoji)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emoji = checkEmoji(emoji)
	local data, err
	if emoji then
		data, err = self.api:deleteAllReactionsForEmoji(channelId, messageId, emoji)
	else
		data, err = self.api:deleteAllReactions(channelId, messageId)
	end
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:getReactionUsers(channelId, messageId, emoji, limit, whence, userId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emoji = checkEmoji(emoji)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(userId)
	end
	local data, err = self.api:getReactions(channelId, messageId, emoji, query)
	if data then
		return self.state:newUsers(data)
	else
		return nil, err
	end
end

function Client:crosspostMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:crosspostMessage(channelId, messageId)
	if data then
		return self.state:newMessage(data)
	else
		return nil, err
	end
end

function Client:followNewsChannel(channelId, targetId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:followNewsChannel(channelId, {
		webhook_channel_id = checkSnowflake(targetId),
	})
	if data then
		return data.webhook_id
	else
		return nil, err
	end
end

return Client
