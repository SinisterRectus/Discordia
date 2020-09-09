local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local Emoji = require('../containers/Emoji')
local Guild = require('../containers/Guild')
local Invite = require('../containers/Invite')
local Member = require('../containers/Member')
local Message = require('../containers/Message')
local Role = require('../containers/Role')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')

local fs = require('fs')
local json = require('json')
local pathjoin = require('pathjoin')
local enums = require('../enums')
local typing = require('../typing')

local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger
local checkType = typing.checkType
local checkImageData = typing.checkImageData
local checkSnowflakeArray = typing.checkSnowflakeArray
local format = string.format
local concat, insert, remove = table.concat, table.insert, table.remove
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPaths

local function opt(obj, fn, extra)
	if obj == nil or obj == json.null then
		return obj
	end
	if extra then
		return fn(extra, obj)
	else
		return fn(obj)
	end
end

local channelMap = {}

local function newMessage(channelId, data, client)
	local guildId = channelMap[channelId]
	if guildId == nil then
		local channel, err = client:getChannel(channelId)
		if channel then
			guildId = channel.guildId or '@me'
			channelMap[channelId] = guildId
		else
			return nil, err
		end
	end
	if guildId ~= '@me' then
		data.guild_id = guildId
	end
	return Message(data, client)
end

local methods = {}

---- base ----

function methods:getGatewayURL()
	local data, err = self.api:getGateway()
	if data then
		return data.url
	else
		return nil, err
	end
end

function methods:modifyCurrentUser(payload)
	payload = checkType('table', payload)
	local data, err = self.api:modifyCurrentUser {
		avatar = opt(payload.avatar, checkImageData),
		username = opt(payload.username, checkType, 'string'),
	}
	if data then
		return User(data, self)
	else
		return nil, err
	end
end

function methods:getChannel(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannel(channelId)
	if data then
		channelMap[data.id] = data.guild_id or '@me'
		return Channel(data, self)
	else
		return nil, err
	end
end

function methods:getGuild(guildId, counts)
	guildId = checkSnowflake(guildId)
	local query = counts and {with_counts = true} or nil
	local data, err = self.api:getGuild(guildId, query)
	if data then
		return Guild(data, self)
	else
		return nil, err
	end
end

function methods:getWebhook(webhookId)
	webhookId = checkSnowflake(webhookId)
	local data, err = self.api:getWebhook(webhookId)
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

function methods:getInvite(code, counts)
	code = checkType('string', code)
	local query = counts and {with_counts = true} or nil
	local data, err = self.api:getInvite(code, query)
	if data then
		return Invite(data, self)
	else
		return nil, err
	end
end

function methods:getUser(userId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getUser(userId)
	if data then
		return User(data, self)
	else
		return nil, err
	end
end

---- Guild ----

function methods:modifyGuild(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuild(guildId, {
		name                          = opt(payload.name, checkType, 'string'),
		region                        = opt(payload.region, checkType, 'string'),
		description                   = opt(payload.description, checkType, 'string'),
		preferred_locale              = opt(payload.preferredLocale, checkType, 'string'),
		verification_level            = opt(payload.verificationLevel, checkEnum, enums.verificationLevel),
		default_message_notifications = opt(payload.notificationSetting, checkEnum, enums.notificationSetting),
		explicit_content_filter       = opt(payload.explicitContentLevel, checkEnum, enums.explicitContentLevel),
		afk_timeout                   = opt(payload.aftTimeout, checkInteger),
		afk_channel_id                = opt(payload.afkChannelId, checkSnowflake),
		system_channel_id             = opt(payload.systemChannelId, checkSnowflake),
		rules_channel_id              = opt(payload.rulesChannelId, checkSnowflake),
		public_updates_channel_id     = opt(payload.publicUpdatesChannelId, checkSnowflake),
		owner_id                      = opt(payload.ownerId, checkSnowflake),
		icon                          = opt(payload.icon, checkImageData),
		banner                        = opt(payload.banner, checkImageData),
		splash                        = opt(payload.splash, checkImageData),
		discovery_splash              = opt(payload.discoverySplash, checkImageData),
	})
	if data then
		return Guild(data, self)
	else
		return nil, err
	end
end

function methods:getGuildMember(guildId, userId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getGuildMember(guildId, userId)
	if data then
		data.guild_id = guildId
		return Member(data, self)
	else
		return nil, err
	end
end

function methods:getGuildEmoji(guildId, emojiId)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	local data, err = self.api:getGuildEmoji(guildId, emojiId)
	if data then
		data.guild_id = guildId
		return Emoji(data, self)
	else
		return nil, err
	end
end

function methods:getGuildMembers(guildId, limit, after)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:listGuildMembers(guildId, {
		limit = limit and checkInteger(limit) or nil,
		after = after and checkSnowflake(after) or nil,
	})
	if data then
		for i, v in ipairs(data) do
			v.guild_id = guildId
			data[i] = Member(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildRoles(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildRoles(guildId)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = guildId
			data[i] = Role(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildEmojis(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildEmojis(guildId)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = guildId
			data[i] = Emoji(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildChannels(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildChannels(guildId)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = guildId
			data[i] = Channel(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:createGuildRole(guildId, payload)
	guildId = checkSnowflake(guildId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createGuildRole(guildId, {
			name        = opt(payload.name, checkType, 'string'),
			permissions = opt(payload.permissions, checkPermissions),
			color       = opt(payload.color, checkColor),
			hoist       = opt(payload.hoisted, checkType, 'boolean'),
			mentionable = opt(payload.mentionable, checkType, 'boolean'),
		})
	else
		data, err = self.api:createGuildRole(guildId, {name = checkType('string', payload)})
	end
	if data then
		data.guild_id = guildId
		return Role(data, self)
	else
		return nil, err
	end
end

function methods:createGuildEmoji(guildId, name, image) -- NOTE: make payload?
	guildId = checkSnowflake(guildId)
	local data, err = self.api:createGuildEmoji(guildId, {
		name = checkType('string', name),
		image = checkImageData(image),
	})
	if data then
		data.guild_id = guildId
		return Emoji(data, self)
	else
		return nil, err
	end
end

function methods:createGuildChannel(guildId, payload)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createGuildChannel(guildId, {
			name = opt(payload.name, checkType, 'string'),
			type = opt(payload.type, checkEnum, enums.channelType),
			topic = opt(payload.topic, checkType, 'string'),
			bitrate = opt(payload.bitrate, checkInteger),
			user_limit = opt(payload.userLimit, checkInteger),
			rate_limit_per_user = opt(payload.rateLimit, checkInteger),
			position = opt(payload.position, checkInteger),
			parent_id = opt(payload.parentId, checkInteger),
			nsfw = opt(payload.nsfw, checkType, 'boolean'),
			-- TODO: permission_overwrites
		})
	else
		data, err = self.api:createGuildChannel(guildId, {name = checkType('string', payload)})
	end
	if data then
		channelMap[data.id] = data.guild_id or '@me'
		return Channel(data, self)
	else
		return nil, err
	end
end

function methods:getGuildPruneCount(guildId, days)
	guildId = checkSnowflake(guildId)
	local query = days and {days = checkInteger(days)} or nil
	local data, err = self.api:getGuildPruneCount(guildId, query)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

function methods:pruneGuildMembers(guildId, payload)
	guildId = checkSnowflake(guildId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:beginGuildPrune(guildId, {
			days = opt(payload.days, checkInteger),
			compute_prune_count = opt(payload.compute, checkType, 'boolean'),
			include_roles = opt(payload.roleIds, checkSnowflakeArray),
		})
	else
		data, err = self.api:beginGuildPrune(guildId)
	end
	if data then
		return data.pruned
	else
		return nil, err
	end
end

function methods:getGuildBan(guildId, userId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getGuildBan(guildId, userId)
	if data then
		data.guild_id = guildId
		return Ban(data, self)
	else
		return nil, err
	end
end

function methods:getGuildBans(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildBans(guildId)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = guildId
			data[i] = Ban(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildInvites(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildInvites(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = Invite(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildWebhooks(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildWebhooks(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = Webhook(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getGuildAuditLogs(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:getGuildAuditLog(guildId, {
		user_id = opt(payload.userId, checkSnowflake),
		action_type = opt(payload.actionType, checkEnum, enums.actionType),
		before = opt(payload.before, checkSnowflake),
		limit = opt(payload.limit, checkInteger),
	})
	if data then
		for i, v in ipairs(data.audit_log_entries) do
			v.guild_id = guildId
			data.audit_log_entries[i] = AuditLogEntry(v, self)
		end
		-- TODO: users and webhooks
		return data.audit_log_entries
	else
		return nil, err
	end
end

function methods:leaveGuild(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:leaveGuild(guildId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:deleteGuild(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:deleteGuild(guildId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:removeGuildMember(guildId, userId, reason)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local query = reason and {reason = checkType('string', reason)} or nil
	local data, err = self.api:removeGuildMember(guildId, userId, query)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:createGuildBan(guildId, userId, reason, days)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local data, err = self.api:createGuildBan(guildId, checkSnowflake(userId), {
		reason = reason and checkType('string', reason) or nil,
		delete_message_days = days and checkInteger(days) or nil,
	})
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:removeGuildBan(guildId, userId, reason)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local query = reason and {reason = checkType('string', reason)} or nil
	local data, err = self.api:removeGuildBan(guildId, checkSnowflake(userId), query)
	if data then
		return true -- 204
	else
		return false, err
	end
end

---- Emoji ----

function methods:modifyGuildEmoji(guildId, emojiId, payload)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildEmoji(guildId, emojiId, {
		name = opt(payload.name, checkType, 'string'),
		roles = opt(payload.roleIds, checkSnowflakeArray),
	})
	if data then
		data.guild_id = guildId
		return Emoji(data, self)
	else
		return nil, err
	end
end

function methods:deleteGuildEmoji(guildId, emojiId)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	local data, err = self.api:deleteGuildEmoji(guildId, emojiId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

---- Role ----

function methods:modifyGuildRole(guildId, roleId, payload)
	guildId = checkSnowflake(guildId)
	roleId = checkSnowflake(roleId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildRole(guildId, roleId, {
		name        = opt(payload.name, checkType, 'string'),
		permissions = opt(payload.permissions, checkPermissions),
		color       = opt(payload.color, checkColor),
		hoist       = opt(payload.hoisted, checkType, 'boolean'),
		mentionable = opt(payload.mentionable, checkType, 'boolean'),
	})
	if data then
		data.guild_id = guildId
		return Role(data, self)
	else
		return nil, err
	end
end

function methods:deleteGuildRole(guildId, roleId)
	guildId = checkSnowflake(guildId)
	roleId = checkSnowflake(roleId)
	local data, err = self.api:deleteGuildRole(guildId, roleId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

---- Member ----

function methods:modifyGuildMember(guildId, userId, payload)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildMember(guildId, userId, {
		nick = opt(payload.nickname, checkType, 'string'),
		roles = opt(payload.roleIds, checkSnowflakeArray),
		mute = opt(payload.muted, checkType, 'boolean'),
		deaf = opt(payload.deafened, checkType, 'boolean'),
		channel_id = opt(payload.channelId, checkSnowflake),
	})
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:addGuildMemberRole(guildId, userId, roleId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	roleId = checkSnowflake(roleId)
	if roleId == guildId then
		return nil, 'Cannot add "everyone" role'
	end
	local data, err = self.api:addGuildMemberRole(guildId, userId, roleId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:removeGuildMemberRole(guildId, userId, roleId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	roleId = checkSnowflake(roleId)
	if roleId == guildId then
		return nil, 'Cannot remove "everyone" role'
	end
	local data, err = self.api:removeGuildMemberRole(guildId, userId, roleId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

---- Channel ----

function methods:modifyChannel(channelId, payload)
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
		-- TODO: permission_overwrites
	})
	if data then
		channelMap[data.id] = data.guild_id or '@me'
		return Channel(data, self)
	else
		return nil, err
	end
end

function methods:deleteChannel(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:deleteChannel(channelId)
	if data then
		return true -- 200
	else
		return false, err
	end
end

function methods:createChannelInvite(channelId, payload)
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
		return Invite(data, self)
	else
		return nil, err
	end
end

function methods:getChannelInvites(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelInvites(channelId)
	if data then
		for i, v in ipairs(data) do
			data[i] = Invite(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:createWebhook(channelId, payload)
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
		return Webhook(data, self)
	else
		return nil, err
	end
end

function methods:getChannelWebhooks(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannelWebhooks(channelId)
	if data then
		for i, v in ipairs(data) do
			data[i] = Webhook(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:bulkDeleteMessages(channelId, messageIds)
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

function methods:getChannelMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:getChannelMessage(channelId, messageId)
	if data then
		return newMessage(channelId, data, self)
	else
		return nil, err
	end
end

function methods:getChannelMessages(channelId, limit, whence, messageId)
	channelId = checkSnowflake(channelId)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(messageId)
	end
	local data, err = self.api:getChannelMessages(channelId, query)
	if data then
		for i, v in ipairs(data) do
			data[i] = newMessage(channelId, v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:getPinnedMessages(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getPinnedMessages(channelId)
	if data then
		for i, v in ipairs(data) do
			data[i] = newMessage(channelId, v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:triggerTypingIndicator(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:triggerTypingIndicator(channelId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

local function parseMention(obj, mentions)
	if not pcall(function()
		mentions = mentions or {}
		insert(mentions, checkType('string', obj.mentionString))
	end) then
		return nil, 'Unmentionable object: ' .. tostring(obj)
	end
	return mentions
end

local function parseFile(obj, files)
	if type(obj) == 'string' then
		local data, err = readFileSync(obj)
		if not data then
			return nil, err
		end
		files = files or {}
		insert(files, {remove(splitPath(obj)), data})
		return files
	elseif type(obj) == 'table' and type(obj[1]) == 'string' and type(obj[2]) == 'string' then
		files = files or {}
		insert(files, obj)
		return files
	else
		return nil, 'Invalid file object: ' .. tostring(obj)
	end
end

function methods:createMessage(channelId, payload)

	channelId = checkSnowflake(channelId)

	local data, err

	if type(payload) == 'table' then

		local content = payload.content

		if type(payload.code) == 'string' then
			content = format('```%s\n%s\n```', payload.code, content)
		elseif payload.code == true then
			content = format('```\n%s```', content)
		end

		local mentions
		if payload.mention then
			mentions, err = parseMention(payload.mention)
			if err then
				return nil, err
			end
		end

		if type(payload.mentions) == 'table' then
			for _, mention in ipairs(payload.mentions) do
				mentions, err = parseMention(mention, mentions)
				if err then
					return nil, err
				end
			end
		end

		if mentions then
			insert(mentions, content)
			content = concat(mentions, ' ')
		end

		local files
		if payload.file then
			files, err = parseFile(payload.file)
			if err then
				return nil, err
			end
		end

		if type(payload.files) == 'table' then
			for _, file in ipairs(payload.files) do
				files, err = parseFile(file, files)
				if err then
					return nil, err
				end
			end
		end

		data, err = self.api:createMessage(channelId, {
			content = content,
			tts = opt(payload.tts, checkType, 'boolean'),
			nonce = opt(payload.nonce, checkSnowflake),
			embed = opt(payload.embed, checkType, 'table'),
		}, nil, files)

	else

		data, err = self.api:createMessage(channelId, {content = payload})

	end

	if data then
		return newMessage(channelId, data, self)
	else
		return nil, err
	end

end

---- Invite ----

function methods:deleteInvite(code)
	code = checkType('string', code)
	local data, err = self.api:deleteInvite(code)
	if data then
		return true -- 200
	else
		return false, err
	end
end

---- Message ----

function methods:editMessage(channelId, messageId, payload)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	payload = checkType('table', payload)
	local data, err = self.api:editMessage(channelId, messageId, {
		content = opt(payload.content, checkType, 'string'),
		embed = opt(payload.embed, checkType, 'table'),
		flags = opt(payload.flags, checkInteger),
	})
	if data then
		return newMessage(channelId, data, self)
	else
		return nil, err
	end
end

function methods:deleteMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:deleteMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:pinMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:addPinnedChannelMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:unpinMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:deletePinnedChannelMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function methods:addReaction(channelId, messageId, emojiHash)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emojiHash = checkType('string', emojiHash)
	local data, err = self.api:createReaction(channelId, messageId, emojiHash)
	if data then
		return true
	else
		return false, err
	end
end

function methods:removeReaction(channelId, messageId, emojiHash, userId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emojiHash = checkType('string', emojiHash)
	local data, err
	if userId then
		userId = checkSnowflake(userId)
		data, err = self.api:deleteUserReaction(channelId, messageId, emojiHash, userId)
	else
		data, err = self.api:deleteOwnReaction(channelId, messageId, emojiHash)
	end
	if data then
		return true
	else
		return false, err
	end
end

function methods:clearAllReactions(channelId, messageId, emojiHash)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emojiHash = checkType('string', emojiHash)
	local data, err
	if emojiHash then
		data, err = self.api:deleteAllReactionsForEmoji(channelId, messageId, emojiHash)
	else
		data, err = self.api:deleteAllReactions(channelId, messageId)
	end
	if data then
		return true
	else
		return false, err
	end
end

function methods:getReactionUsers(channelId, messageId, emojiHash, limit, whence, userId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	emojiHash = checkType('string', emojiHash)
	local query = {limit = limit and checkInteger(limit)}
	if whence then
		query[checkEnum(enums.whence, whence)] = checkSnowflake(userId)
	end
	local data, err = self.api:getReactions(channelId, messageId, emojiHash, query)
	if data then
		for i, v in ipairs(data) do
			data[i] = User(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:crosspostMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:crosspostMessage(channelId, messageId)
	if data then
		return newMessage(channelId, data, self)
	else
		return nil, err
	end
end

function methods:followNewsChannel(channelId, targetId)
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

---- User ----

function methods:createDM(userId)
	userId = checkSnowflake(userId)
	local data, err = self.api:createDM {recipient_id = userId}
	if data then
		channelMap[data.id] = data.guild_id or '@me'
		return Channel(data, self)
	else
		return nil, err
	end
end

---- Webhook ----

function methods:modifyWebhook(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyWebhook(guildId, {
		name = opt(payload.name, checkType, 'string'),
		avatar = opt(payload.avatar, checkImageData),
		channel_id = opt(payload.channelId, checkSnowflake),
	})
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

function methods:deleteWebhook(webhookId)
	webhookId = checkSnowflake(webhookId)
	local data, err = self.api:deleteWebhook(webhookId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

return {
	methods = methods,
}
