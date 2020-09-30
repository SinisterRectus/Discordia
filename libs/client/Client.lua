local uv = require('uv')
local json = require('json')
local class = require('../class')
local enums = require('../enums')
local helpers = require('../helpers')
local typing = require('../typing')
local constants = require('../constants')
local package = require('../../package')
local fs = require('fs')
local pathjoin = require('pathjoin')

local Logger = require('../utils/Logger')
local Emitter = require('../utils/Emitter')
local API = require('./API')
local CDN = require('./CDN')
local Shard = require('./Shard')
local State = require('./State')

local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')

local Bitfield = require('../utils/Bitfield')
local Color = require('../utils/Color')

local wrap = coroutine.wrap
local concat, insert, remove = table.concat, table.insert, table.remove
local format = string.format
local floor = math.floor
local attachQuery, readOnly = helpers.attachQuery, helpers.readOnly
local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger
local checkType = typing.checkType
local checkImageData = typing.checkImageData
local checkSnowflakeArray = typing.checkSnowflakeArray
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPaths

local GATEWAY_VERSION = constants.GATEWAY_VERSION
local GATEWAY_ENCODING = constants.GATEWAY_ENCODING

local Client, get = class('Client', Emitter)

local function checkOption(options, k, expected, default)
	if options == nil then
		return default
	end
	local v = options[k]
	if v == nil then
		return default
	end
	local received = type(v)
	if expected ~= received then
		return error(format('invalid client option %q (expected %s, received %s)', k, expected, received), 3)
	end
	if received == 'number' and (v < 0 or v % 1 > 0) then
		return error(format('invalid client option %q (number must be a positive integer)', k), 3)
	end
	return v
end

local function checkActivity(activity)
	local t = type(activity)
	if t == 'string' then
		return {name = activity, type = 0}
	elseif t == 'table' then
		return {
			name = type(activity.name) == 'string' and activity.name or '',
			type = type(activity.type) == 'number' and activity.type or 0,
			url = type(activity.url) == 'string' and activity.url or nil,
		}
	end
	return error('invalid activity', 2)
end

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

local function checkColor(obj)
	if class.isInstance(obj, Color) then
		return obj:toDec()
	end
	return checkInteger(obj)
end

local function checkBitfield(obj)
	if class.isInstance(obj, Bitfield) then
		return obj:toDec()
	end
	return checkInteger(obj)
end

function Client:__init(options)
	Emitter.__init(self)
	self._routeDelay = checkOption(options, 'routeDelay', 'number', 250)
	self._maxRetries = checkOption(options, 'maxRetries', 'number', 5)
	self._tokenPrefix = checkOption(options, 'tokenPrefix', 'string', 'Bot ')
	self._gatewayIntents = checkOption(options, 'gatewayIntents', 'number', nil)
	self._totalShardCount = checkOption(options, 'totalShardCount', 'number', nil)
	self._payloadCompression = checkOption(options, 'payloadCompression', 'boolean', true)
	self._defaultImageExtension = checkOption(options, 'defaultImageExtension', 'string', 'png')
	self._defaultImageSize = checkOption(options, 'defaultImageSize', 'number', 1024)
	self._logger = Logger(
		checkOption(options, 'logLevel', 'number', enums.logLevel.info),
		checkOption(options, 'dateFormat', 'string', '%F %T'),
		checkOption(options, 'logFile', 'string', 'discordia.log'),
		checkOption(options, 'logColors', 'boolean', true)
	)
	self._api = API(self)
	self._cdn = CDN(self)
	self._state = State(self)
	self._shards = {}
	self._token = nil
	self._userId = nil
	self._status = options.status and checkEnum(enums.status, options.status)
	self._activity = options.activity and checkActivity(options.activity)
end

function Client:_run(token)

	self:log('info', 'Discordia %s', package.version)
	self:log('info', 'Connecting to Discord...')

	local signal = uv.new_signal()
	signal:start(uv.constants.SIGINT, function()
		signal:stop()
		signal:close()
		return wrap(self.stop)(self)
	end)

	self:setToken(token)

	local user, err1 = self.api:getCurrentUser()
	if not user then
		return self:log('critical', 'Could not get user information: %s', err1)
	end
	self._userId = user.id
	self.state:newUser(user)
	self:log('info', 'Authenticated as %s#%s', user.username, user.discriminator)

	local shards = self._totalShardCount
	if shards == 0 then
		self:log('info', 'Readying client with no gateway connection(s)')
		return self:emit('ready')
	end

	local gateway, err2 = self.api:getGatewayBot()
	if not gateway then
		return self:log('critical', 'Could not get gateway information: %s', err2)
	end

	if shards == nil then
		shards = gateway.shards
	elseif shards ~= gateway.shards then
		self:log('warning', 'Indicated shard count (%i) is different from recommended (%i)', shards, gateway.shards)
	end
	self._totalShardCount = shards

	local l = gateway.session_start_limit
	self:log('info', '%i of %i session starts consumed', l.total - l.remaining, l.total)

	for id = 0, shards - 1 do
		self._shards[id] = Shard(id, self)
	end

	local path = {'/'}
	attachQuery(path, {v = GATEWAY_VERSION, encoding = GATEWAY_ENCODING})
	path = concat(path)

	for id = 0, shards - 1 do
		local shard = self._shards[id]
		wrap(shard.connect)(shard, gateway.url, path)
		shard:identifyWait()
	end

end

----

function Client:log(level, msg, ...)
	return self._logger:log(level, msg, ...)
end

function Client:run(token)
	return wrap(self._run)(self, token)
end

function Client:stop()
	for _, shard in pairs(self._shards) do
		shard:disconnect(false)
	end
end

function Client:setToken(token)
	self._token = token
	self.api:setToken(token)
end

function Client:setStatus(status)
	self._status = status and checkEnum(enums.status, status)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._status, self._activity)
	end
end

function Client:setActivity(activity)
	self._activity = activity and checkActivity(activity)
	for _, shard in pairs(self._shards) do
		shard:updatePresence(self._status, self._activity)
	end
end

function Client:setUsername(username)
	return self:modifyCurrentUser({username = username or json.null})
end

function Client:setAvatar(avatar)
	return self:modifyCurrentUser({avatar = avatar or json.null})
end

function Client:getGuildShardId(guildId)
	return floor(checkSnowflake(guildId) / 2^22) % self.totalShardCount
end

---- base ----

function Client:getGatewayURL()
	local data, err = self.api:getGateway()
	if data then
		return data.url
	else
		return nil, err
	end
end

function Client:modifyCurrentUser(payload)
	payload = checkType('table', payload)
	local data, err = self.api:modifyCurrentUser {
		avatar = opt(payload.avatar, checkImageData),
		username = opt(payload.username, checkType, 'string'),
	}
	if data then
		return self.state:newUser(data)
	else
		return nil, err
	end
end

function Client:getChannel(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getChannel(channelId)
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

function Client:getGuild(guildId, counts)
	guildId = checkSnowflake(guildId)
	local query = counts and {with_counts = true} or nil
	local data, err = self.api:getGuild(guildId, query)
	if data then
		return self.state:newGuild(data)
	else
		return nil, err
	end
end

function Client:getWebhook(webhookId)
	webhookId = checkSnowflake(webhookId)
	local data, err = self.api:getWebhook(webhookId)
	if data then
		return self.state:newWebhook(data)
	else
		return nil, err
	end
end

function Client:getInvite(code, counts)
	code = checkType('string', code)
	local query = counts and {with_counts = true} or nil
	local data, err = self.api:getInvite(code, query)
	if data then
		return self.state:newInvite(data)
	else
		return nil, err
	end
end

function Client:getUser(userId)
	userId = checkSnowflake(userId)
	local data, err = self.api:getUser(userId)
	if data then
		return self.state:newUser(data)
	else
		return nil, err
	end
end

---- Guild ----

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

function Client:getGuildEmoji(guildId, emojiId)
	guildId = checkSnowflake(guildId)
	emojiId = checkSnowflake(emojiId)
	local data, err = self.api:getGuildEmoji(guildId, emojiId)
	if data then
		return self.state:newEmoji(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildMembers(guildId, limit, after)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:listGuildMembers(guildId, {
		limit = limit and checkInteger(limit) or nil,
		after = after and checkSnowflake(after) or nil,
	})
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newMember(guildId, v)
		end
		return data
	else
		return nil, err
	end
end

function Client:getGuildRoles(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildRoles(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newRole(guildId, v)
		end
		return data
	else
		return nil, err
	end
end

function Client:getGuildEmojis(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildEmojis(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newEmoji(guildId, v)
		end
		return data
	else
		return nil, err
	end
end

function Client:getGuildChannels(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildChannels(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newChannel(v)
		end
		return data
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

function Client:createGuildEmoji(guildId, name, image) -- NOTE: make payload?
	guildId = checkSnowflake(guildId)
	local data, err = self.api:createGuildEmoji(guildId, {
		name = checkType('string', name),
		image = checkImageData(image),
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
			-- TODO: permission_overwrites
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
		data.guild_id = guildId
		return Ban(data, self)
	else
		return nil, err
	end
end

function Client:getGuildBans(guildId)
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

function Client:getGuildInvites(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildInvites(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newInvite(v)
		end
		return data
	else
		return nil, err
	end
end

function Client:getGuildWebhooks(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildWebhooks(guildId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newWebhook(v)
		end
		return data
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
		for i, v in ipairs(data.audit_log_entries) do
			v.guild_id = guildId
			data.audit_log_entries[i] = AuditLogEntry(v, self)
		end
		for _, v in ipairs(data.users) do
			self.state:newUser(v)
		end
		return data.audit_log_entries
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

---- Emoji ----

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

---- Role ----

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

---- Member ----

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
		return true -- 204
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

---- Channel ----

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
		-- TODO: permission_overwrites
	})
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

function Client:deleteChannel(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:deleteChannel(channelId)
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
		for i, v in ipairs(data) do
			data[i] = self.state:newInvite(v)
		end
		return data
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
		for i, v in ipairs(data) do
			data[i] = self.state:newWebhook(v)
		end
		return data
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
		return self.state:newMessage(channelId, data)
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
		for i, v in ipairs(data) do
			data[i] = self.state:newMessage(channelId, v)
		end
		return data
	else
		return nil, err
	end
end

function Client:getPinnedMessages(channelId)
	channelId = checkSnowflake(channelId)
	local data, err = self.api:getPinnedMessages(channelId)
	if data then
		for i, v in ipairs(data) do
			data[i] = self.state:newMessage(channelId, v)
		end
		return data
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

function Client:createMessage(channelId, payload)

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
		return self.state:newMessage(channelId, data)
	else
		return nil, err
	end

end

---- Invite ----

function Client:deleteInvite(code)
	code = checkType('string', code)
	local data, err = self.api:deleteInvite(code)
	if data then
		return true -- 200
	else
		return false, err
	end
end

---- Message ----

function Client:editMessage(channelId, messageId, payload)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	payload = checkType('table', payload)
	local data, err = self.api:editMessage(channelId, messageId, {
		content = opt(payload.content, checkType, 'string'),
		embed = opt(payload.embed, checkType, 'table'),
		flags = opt(payload.flags, checkInteger),
	})
	if data then
		return self.state:newMessage(channelId, data)
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
	local data, err = self.api:addPinnedChannelMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:unpinMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:deletePinnedChannelMessage(channelId, messageId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

function Client:addReaction(channelId, messageId, emojiHash)
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

function Client:removeReaction(channelId, messageId, emojiHash, userId)
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

function Client:clearAllReactions(channelId, messageId, emojiHash)
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

function Client:getReactionUsers(channelId, messageId, emojiHash, limit, whence, userId)
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
			data[i] = self.state:newUser(v)
		end
		return data
	else
		return nil, err
	end
end

function Client:crosspostMessage(channelId, messageId)
	channelId = checkSnowflake(channelId)
	messageId = checkSnowflake(messageId)
	local data, err = self.api:crosspostMessage(channelId, messageId)
	if data then
		return self.state:newMessage(channelId, data)
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

---- User ----

function Client:createDM(userId)
	userId = checkSnowflake(userId)
	local data, err = self.api:createDM {recipient_id = userId}
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

---- Webhook ----

function Client:modifyWebhook(guildId, payload)
	guildId = checkSnowflake(guildId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyWebhook(guildId, {
		name = opt(payload.name, checkType, 'string'),
		avatar = opt(payload.avatar, checkImageData),
		channel_id = opt(payload.channelId, checkSnowflake),
	})
	if data then
		return self.state:newWebhook(data)
	else
		return nil, err
	end
end

function Client:deleteWebhook(webhookId)
	webhookId = checkSnowflake(webhookId)
	local data, err = self.api:deleteWebhook(webhookId)
	if data then
		return true -- 204
	else
		return false, err
	end
end

----

function get:ready()
	for _, shard in pairs(self._shards) do
		if not shard.ready then
			return false
		end
	end
	return true
end

function get:routeDelay()
	return self._routeDelay
end

function get:maxRetries()
	return self._maxRetries
end

function get:tokenPrefix()
	return self._tokenPrefix
end

function get:gatewayIntents()
	return self._gatewayIntents
end

function get:totalShardCount()
	return self._totalShardCount
end

function get:payloadCompression()
	return self._payloadCompression
end

function get:defaultImageExtension()
	return self._defaultImageExtension
end

function get:defaultImageSize()
	return self._defaultImageSize
end

function get:status()
	return self._status
end

function get:activity()
	return readOnly(self._activity)
end

function get:logger()
	return self._logger
end

function get:token()
	return self._token
end

function get:api()
	return self._api
end

function get:cdn()
	return self._cdn
end

function get:state()
	return self._state
end

function get:userId()
	return self._userId
end

return Client
