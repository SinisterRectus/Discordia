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
local Stopwatch = require('../utils/Stopwatch')
local API = require('./API')
local CDN = require('./CDN')
local Shard = require('./Shard')
local State = require('./State')

local Bitfield = require('../utils/Bitfield')
local Color = require('../utils/Color')

local Emoji = require('../containers/Emoji')
local Reaction = require('../containers/Reaction')

local wrap = coroutine.wrap
local concat, insert, remove = table.concat, table.insert, table.remove
local format = string.format
local floor = math.floor
local attachQuery, readOnly = helpers.attachQuery, helpers.readOnly
local nonce = helpers.nonce
local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger
local checkType = typing.checkType
local checkCallable = typing.checkCallable
local checkImageData = typing.checkImageData
local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension
local checkSnowflakeArray = typing.checkSnowflakeArray
local readFileSync = fs.readFileSync
local splitPath = pathjoin.splitPath
local isInstance = class.isInstance

local GATEWAY_VERSION = constants.GATEWAY_VERSION
local GATEWAY_ENCODING = constants.GATEWAY_ENCODING

local Client, get = class('Client', Emitter)

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

local function checkColor(obj)
	if isInstance(obj, Color) then
		return obj:toDec()
	end
	return Color(obj):toDec()
end

local function checkBitfield(obj)
	if isInstance(obj, Bitfield) then
		return obj:toDec()
	end
	return Bitfield(obj):toDec()
end

local function checkEmoji(obj)
	if type(obj) == 'string' then
		return obj
	elseif isInstance(obj, Emoji) then
		return obj.hash
	elseif isInstance(obj, Reaction) then
		return obj.emojiHash
	else
		return error('invalid emoji', 2)
	end
end

local function checkPermissionOverwrites(overwrites)
	local ret = {}
	for _, obj in pairs(checkType('table', overwrites)) do
		insert(ret, {
			id = checkSnowflake(obj.id),
			type = checkEnum(enums.permissionOverwriteType, obj.type),
			allow = checkBitfield(obj.allowedPermissions),
			deny = checkBitfield(obj.deniedPermissions),
		})
	end
	return ret
end

local function checkPositions(positions)
	local ret = {}
	for k, v in pairs(checkType('table', positions)) do
		insert(ret, {id = checkSnowflake(k), position = checkInteger(v)})
	end
	return ret
end

local function checkIntents(intents)
	if not isInstance(intents, Bitfield) then
		intents = Bitfield(intents)
	end
	if not intents:hasValue(enums.gatewayIntent.guilds) then
		return error('"guilds" intent must be included')
	end
	return intents:toDec()
end

local defaultIntents = Bitfield(enums.gatewayIntent)
defaultIntents:disableValue(enums.gatewayIntent.guildMembers)
defaultIntents:disableValue(enums.gatewayIntent.guildPresences)

local defaultOptions = {
	routeDelay = {250, function(o) return checkInteger(o, 10, 0) end},
	maxRetries = {5, function(o) return checkInteger(o, 10, 0) end},
	latencyLimit = {15, function(o) return checkInteger(o, 10, 1) end},
	tokenPrefix = {'Bot ', function(o) return checkType('string', o) end},
	gatewayIntents = {defaultIntents:toDec(), checkIntents},
	totalShardCount = {nil, function(o) return checkInteger(o, 10, 1) end},
	payloadCompression = {true, function(o) return checkType('boolean', o) end},
	defaultImageExtension = {'png', checkImageExtension},
	defaultImageSize = {1024, checkImageSize},
	logLevel = {enums.logLevel.info, function(o) return checkEnum(enums.logLevel, o) end},
	dateFormat = {'%F %T', function(o) return checkType('string', o) end},
	logFile = {'discordia.log', function(o) return checkType('string', o) end},
	logColors = {true, function(o) return checkType('boolean', o) end},
	status = {nil, function(o) return checkEnum(enums.status, o) end},
	activity = {nil, checkActivity},
}

local function checkOptions(customOptions)
	local options = {}
	for k, v in pairs(defaultOptions) do
		options[k] = v[1]
	end
	if type(customOptions) == 'table' then
		for k, v in pairs(customOptions) do
			local default = defaultOptions[k]
			if not default then
				return error(format('invalid client option %q', k), 3)
			end
			local success, res = pcall(default[2], v)
			if not success then
				return error(format('invalid client option %q: %s', k, res), 3)
			end
			options[k] = res
		end
	end
	return options
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

function Client:__init(options)
	Emitter.__init(self)
	options = checkOptions(options)
	self._routeDelay = options.routeDelay
	self._maxRetries = options.maxRetries
	self._latencyLimit = options.latencyLimit
	self._tokenPrefix = options.tokenPrefix
	self._gatewayEnabled = options.gatewayEnabled
	self._gatewayIntents = options.gatewayIntents
	self._totalShardCount = options.totalShardCount
	self._payloadCompression = options.payloadCompression
	self._defaultImageExtension = options.defaultImageExtension
	self._defaultImageSize = options.defaultImageSize
	self._logger = Logger(options.logLevel, options.dateFormat, options.logFile, options.logColors)
	self._api = API(self)
	self._cdn = CDN(self)
	self._state = State(self)
	self._sw = Stopwatch()
	self._shards = {}
	self._token = nil
	self._userId = nil
	self._status = options.status
	self._activity = options.activity
end

function Client:_run(token)

	token = checkType('string', token)

	self:log('info', 'Discordia %s', package.version)
	self:log('info', 'Connecting to Discord...')

	local signal = uv.new_signal()
	signal:start(uv.constants.SIGINT, function()
		signal:stop()
		signal:close()
		return wrap(self.stop)(self)
	end)

	self._token = token
	self.api:setToken(token)

	local user, err1 = self.api:getCurrentUser()
	if not user then
		return self:log('critical', 'Could not get user information: %s', err1)
	end
	self._userId = user.id
	self.state:newUser(user)
	self:log('info', 'Authenticated as %s#%s', user.username, user.discriminator)

	local gateway, err2 = self.api:getGatewayBot()
	if not gateway then
		return self:log('critical', 'Could not get gateway information: %s', err2)
	end

	local shards = self._totalShardCount
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

function Client:requestGuildMembers(guildId, payload, callback)

	guildId = checkSnowflake(guildId)
	local shardId = self:getGuildShardId(guildId)
	local shard = self._shards[shardId]
	if not shard then
		return nil, 'shard does not exist'
	end

	if payload and callback then

		payload = checkType('table', payload)
		callback = checkCallable(callback)

		if payload.query and payload.users then
			return error('query and users field are mutually exclusive', 2)
		end

		local query, users
		if payload.users then
			users = opt(payload.users, checkSnowflakeArray)
		else
			query = opt(payload.query, checkType, 'string') or ''
		end

		payload = {
			guild_id = guildId,
			query = query,
			limit = opt(payload.limit, checkType, 'number') or 0,
			presences = opt(payload.presences, checkType, 'boolean'),
			user_ids = users,
			nonce = nonce(32),
		}

	else

		callback = checkCallable(payload)
		payload = {
			guild_id = guildId,
			query = '',
			limit = 0,
			nonce = nonce(32),
		}

	end

	return shard:requestGuildMembers(payload, callback)

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

function Client:getGuild(guildId, withCounts)
	guildId = checkSnowflake(guildId)
	local query = withCounts and {with_counts = true} or nil
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

function Client:getInvite(code, withCounts)
	code = checkType('string', code)
	local query = withCounts and {with_counts = true} or nil
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
		return self.state:newMembers(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildRoles(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildRoles(guildId)
	if data then
		return self.state:newRoles(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildEmojis(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildEmojis(guildId)
	if data then
		return self.state:newEmojis(guildId, data)
	else
		return nil, err
	end
end

function Client:getGuildChannels(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildChannels(guildId)
	if data then
		return self.state:newChannels(data)
	else
		return nil, err
	end
end

function Client:getGuildVoiceRegions(guildId)
	guildId = checkSnowflake(guildId)
	local data, err = self.api:getGuildVoiceRegions(guildId)
	if data then
		return data -- raw table
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
		permission_overwrites = opt(payload.permissionOverwrites, checkPermissionOverwrites),
	})
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
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
		return self.state:newMessage(data)
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

function Client:clearAllReactions(channelId, messageId, emoji)
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

function Client:modifyWebhook(webhookId, payload)
	webhookId = checkSnowflake(webhookId)
	payload = checkType('table', payload)
	local data, err = self.api:modifyWebhook(webhookId, {
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

function Client:getGatewayStatistics()
	local stats = {
		eventsReceived = 0,
		commandsTransmitted = 0,
		bytesReceived = 0,
		bytesTransmitted = 0,
	}
	for _, shard in pairs(self._shards) do
		stats.eventsReceived = stats.eventsReceived + shard.eventsReceived
		stats.commandsTransmitted = stats.commandsTransmitted + shard.commandsTransmitted
		stats.bytesReceived = stats.bytesReceived + shard.bytesReceived
		stats.bytesTransmitted = stats.bytesTransmitted + shard.bytesTransmitted
	end
	return stats
end

function get:uptime()
	return self._sw:getTime()
end

function get:apiRequests()
	return self._api.requests
end

function get:apiBytesReceived()
	return self._api.bytesReceived
end

function get:apiBytesTransmitted()
	return self._api.bytesTransmitted
end

function get:apiLatency()
	return readOnly(self._api.latency)
end

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

function get:latencyLimit()
	return self._latencyLimit
end

function get:tokenPrefix()
	return self._tokenPrefix
end

function get:gatewayEnabled()
	return self._gatewayEnabled
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
