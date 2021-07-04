local enums = require('../enums')
local typing = require('../typing')
local helpers = require('../helpers')
local messaging = require('../messaging')

local VoiceRegion = require('../structs/VoiceRegion')

local floor = math.floor

local opt = typing.opt
local checkType = typing.checkType
local checkEnum = typing.checkEnum
local checkInteger = typing.checkInteger
local checkImageData = typing.checkImageData
local checkSnowflake = typing.checkSnowflake
local checkSnowflakeArray = typing.checkSnowflakeArray

local checkColor = messaging.checkColor
local checkBitfield = messaging.checkBitfield
local checkPositions = messaging.checkPositions
local checkWelcomeChannels = messaging.checkWelcomeChannels
local checkPermissionOverwrites = messaging.checkPermissionOverwrites

local Client = {}

function Client:getGuildShardId(guildId)
	return floor(checkSnowflake(guildId) / 2^22) % self.totalShardCount
end

function Client:getGuild(guildId)
	guildId = checkSnowflake(guildId)
	return self.state:getGuild(guildId)
end

function Client:getGuildCounts(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuild(guildId, {with_counts = true})
	if data then
		return {
			maxMembers = data.max_members,
			maxPresences = data.max_presences,
			approximateMemberCount = data.approximate_member_count,
			approximatePresenceCount = data.approximate_presence_count,
		}
	else
		return nil, err
	end
end

function Client:modifyGuild(guildId, payload)
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
		return self.state:newGuild(data)
	else
		return nil, err
	end
end

function Client:getGuildMember(guildId, userId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getGuildMember(guildId, userId)
	if data then
		return self.state:newMember(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildChannel(guildId, channelId)
	guildId = checkSnowflake(guildId)
	channelId = checkSnowflake(channelId)
	return self.state:getGuildChannel(guildId, channelId)
end

function Client:getGuildRole(guildId, roleId)
	guildId = checkSnowflake(guildId)
	roleId = checkSnowflake(roleId)
	return self.state:getGuildRole(guildId, roleId)
end

function Client:getGuildEmoji(guildId, emojiId)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	return self.state:getGuildEmoji(guildId, emojiId)
end

function Client:getGuildMembers(guildId, limit, after)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:listGuildMembers(guildId, {
		limit = limit and checkInteger(limit) or nil,
		after = after and checkSnowflake(after) or nil,
	})
	if data then
		return self.state:newMembers(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildRoles(guildId)
	guildId = checkSnowflake(guildId)
	return self.state:getGuildRoles(guildId)
end

function Client:getGuildEmojis(guildId)
	guildId = checkSnowflake(guildId)
	return self.state:getGuildEmojis(guildId)
end

function Client:getGuildChannels(guildId)
	guildId = checkSnowflake(guildId)
	return self.state:getGuildChannels(guildId)
end

function Client:getGuildVoiceRegions(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildVoiceRegions(guildId)
	if data then
		return helpers.structs(VoiceRegion, data)
	else
		return nil, err
	end
end

function Client:searchGuildMembers(guildId, query, limit)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:searchGuildMembers(guildId, {
		query = checkType('string', query),
		limit = opt(limit, checkType, 'number'),
	})
	if data then
		return self.state:newMembers(guildId, data)
	else
		return nil, err
	end
end

function Client:createGuildRole(guildId, payload)
	guildId = checkSnowflake(guildId)
	local data, err
	if type(payload) == 'table' then
		data, err = self.api:createGuildRole(guildId, {
			name        = opt(payload.name, checkType, 'string'),
			permissions = opt(payload.permissions, checkBitfield),
			color       = opt(payload.color, checkColor),
			hoist       = opt(payload.hoisted, checkType, 'boolean'),
			mentionable = opt(payload.mentionable, checkType, 'boolean'),
		})
	else
		data, err = self.api:createGuildRole(guildId, {name = checkType('string', payload)})
	end
	if data then
		return self.state:newRole(guildId, data)
	else
		return nil, err
	end
end

function Client:createGuildEmoji(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:createGuildEmoji(guildId, {
		name = opt(payload.name, checkType, 'string'),
		image = checkImageData(payload.image),
	})
	if data then
		return self.state:newEmoji(guildId, data)
	else
		return nil, err
	end
end

function Client:createGuildChannel(guildId, payload)
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
			permission_overwrites = opt(payload.permissionOverwrites, checkPermissionOverwrites),
		})
	else
		data, err = self.api:createGuildChannel(guildId, {name = checkType('string', payload)})
	end
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

function Client:getGuildPruneCount(guildId, days)
	guildId = checkSnowflake(guildId)
	local query = days and {days = checkInteger(days)} or nil
	local data, err = self.api:getGuildPruneCount(guildId, query)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

function Client:pruneGuildMembers(guildId, payload)
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

function Client:getGuildBan(guildId, userId)
	guildId = checkSnowflake(guildId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getGuildBan(guildId, userId)
	if data then
		return self.state:newBan(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildBans(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildBans(guildId)
	if data then
		return self.state:newBans(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildInvites(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildInvites(guildId)
	if data then
		return self.state:newInvites(data)
	else
		return nil, err
	end
end

function Client:getGuildWebhooks(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildWebhooks(guildId)
	if data then
		return self.state:newWebooks(data)
	else
		return nil, err
	end
end

function Client:getGuildAuditLogs(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:getGuildAuditLog(guildId, {
		user_id = opt(payload.userId, checkSnowflake),
		action_type = opt(payload.actionType, checkEnum, enums.actionType),
		before = opt(payload.before, checkSnowflake),
		limit = opt(payload.limit, checkInteger),
	})
	if data then
		self.state:newUsers(data.users)
		return self.state:newAuditLogEntries(guildId, data.audit_log_entries)
	else
		return nil, err
	end
end

function Client:leaveGuild(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:leaveGuild(guildId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:deleteGuild(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:deleteGuild(guildId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:removeGuildMember(guildId, userId, reason)
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

function Client:createGuildBan(guildId, userId, reason, days)
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

function Client:removeGuildBan(guildId, userId, reason)
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

function Client:getGuildWelcomeScreen(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildWelcomeScreen(guildId)
	if data then
		return self.state:newWelcomeScreen(guildId, data)
	else
		return nil, err
	end
end

function Client:modifyGuildWelcomeScreen(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildWelcomeScreen(guildId, {
		enabled = opt(payload.enabled, checkType, 'boolean'),
		description = opt(payload.description, checkType, 'string'),
		welcome_channels = opt(payload.welcomeChannels, checkWelcomeChannels),
	})
	if data then
		return self.state:newWelcomeScreen(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildTemplates(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildTemplates(guildId)
	if data then
		return self.state:newGuildTemplates(data)
	else
		return nil, err
	end
end

function Client:createGuildTemplate(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:createGuildTemplate(guildId, {
		name = checkType('string', payload.name),
		description = opt(payload.description, checkType, 'string'),
	})
	if data then
		return self.state:newGuildTemplate(data)
	else
		return nil, err
	end
end

function Client:syncGuildTemplate(guildId, code)
	guildId = checkSnowflake(guildId)
	code = checkType('string', code)
	local data, err = self.api:syncGuildTemplate(guildId, code)
	if data then
		return self.state:newGuildTemplate(data)
	else
		return nil, err
	end
end

function Client:modifyGuildTemplate(guildId, code, payload)
	guildId = checkSnowflake(guildId)
	code = checkType('string', code)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildTemplate(guildId, code, {
		name = opt(payload.name, checkType, 'string'),
		description = opt(payload.description, checkType, 'string'),
	})
	if data then
		return self.state:newGuildTemplate(data)
	else
		return nil, err
	end
end

function Client:deleteGuildTemplate(guildId, code)
	guildId = checkSnowflake(guildId)
	code = checkType('string', code)
	local data, err = self.api:deleteGuildTemplate(guildId, code)
	if data then
		return true -- 200
	else
		return false, err
	end
end

function Client:modifyGuildEmoji(guildId, emojiId, payload)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildEmoji(guildId, emojiId, {
		name = opt(payload.name, checkType, 'string'),
		roles = opt(payload.roleIds, checkSnowflakeArray),
	})
	if data then
		return self.state:newEmoji(guildId, data)
	else
		return nil, err
	end
end

function Client:deleteGuildEmoji(guildId, emojiId)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	local data, err = self.api:deleteGuildEmoji(guildId, emojiId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:modifyGuildRole(guildId, roleId, payload)
	guildId = checkSnowflake(guildId)
	roleId = checkSnowflake(roleId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyGuildRole(guildId, roleId, {
		name        = opt(payload.name, checkType, 'string'),
		permissions = opt(payload.permissions, checkBitfield),
		color       = opt(payload.color, checkColor),
		hoist       = opt(payload.hoisted, checkType, 'boolean'),
		mentionable = opt(payload.mentionable, checkType, 'boolean'),
	})
	if data then
		return self.state:newRole(guildId, data)
	else
		return nil, err
	end
end

function Client:modifyGuildRolePositions(guildId, positions)
	guildId = checkSnowflake(guildId)
	positions = checkPositions(positions)
	local data, err = self.api:modifyGuildRolePositions(guildId, positions)
	if data then
		return self.state:newRoles(guildId, data)
	else
		return nil, err
	end
end

function Client:deleteGuildRole(guildId, roleId)
	guildId = checkSnowflake(guildId)
	roleId = checkSnowflake(roleId)
	local data, err = self.api:deleteGuildRole(guildId, roleId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:modifyGuildMember(guildId, userId, payload)
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
		return self.state:newMember(guildId, data)
	else
		return false, err
	end
end

function Client:addGuildMemberRole(guildId, userId, roleId)
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

function Client:removeGuildMemberRole(guildId, userId, roleId)
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

function Client:modifyGuildChannelPositions(guildId, positions)
	guildId = checkSnowflake(guildId)
	positions = checkPositions(positions)
	local data, err = self.api:modifyGuildChannelPositions(guildId, positions)
	if data then
		return self.state:newChannels(data)
	else
		return nil, err
	end
end

return Client
