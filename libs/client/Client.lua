local uv = require('uv')
local json = require('json')
local class = require('../class')
local enums = require('../enums')
local helpers = require('../helpers')
local typing = require('../typing')
local constants = require('../constants')
local package = require('../../package')

local API = require('./API')
local CDN = require('./CDN')
local Shard = require('./Shard')
local State = require('./State')

local GuildClient = require('./GuildClient')
local ChannelClient = require('./ChannelClient')

local Bitfield = require('../utils/Bitfield')
local Logger = require('../utils/Logger')
local Emitter = require('../utils/Emitter')
local Stopwatch = require('../utils/Stopwatch')

local Application = require('../containers/Application')

local wrap = coroutine.wrap
local concat = table.concat
local format = string.format
local attachQuery, readOnly = helpers.attachQuery, helpers.readOnly
local nonce = helpers.nonce
local opt = typing.opt
local checkEnum = typing.checkEnum
local checkSnowflake = typing.checkSnowflake
local checkInteger = typing.checkInteger
local checkType = typing.checkType
local checkCallable = typing.checkCallable
local checkImageData = typing.checkImageData
local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension
local checkSnowflakeArray = typing.checkSnowflakeArray
local isInstance = class.isInstance

local GATEWAY_VERSION = constants.GATEWAY_VERSION
local GATEWAY_ENCODING = constants.GATEWAY_ENCODING
local MIN_BITRATE, MAX_BITRATE = constants.MIN_BITRATE, constants.MAX_BITRATE

local Client, get = class('Client', Emitter)

class.mixin(Client, GuildClient)
class.mixin(Client, ChannelClient)
class.mixin(Client, CommandClient)

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

local defaultAllowedMentions = {
	users = false, roles = false, everyone = false, repliedUser = false,
}

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
	defaultAllowedMentions = {defaultAllowedMentions, function(o) return checkType('table', o) end},
	defaultBitrate = {64000, function(o) return checkInteger(o, 10, MIN_BITRATE, MAX_BITRATE) end},
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
	self._defaultAllowedMentions = options.defaultAllowedMentions
	self._defaultBitrate = options.defaultBitrate
	self._logger = Logger(options.logLevel, options.dateFormat, options.logFile, options.logColors)
	self._api = API(self)
	self._cdn = CDN(self)
	self._state = State(self)
	self._sw = Stopwatch()
	self._shards = {}
	self._token = nil
	self._userId = nil
	self._user = nil
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
	self._user = self.state:newUser(user)
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

function Client:getApplication()
	local data, err = self.api:getCurrentBotApplicationInformation()
	if data then
		return Application(data, self)
	else
		return nil, err
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

function Client:getGuildTemplate(code)
	code = checkType('string', code)
	local data, err = self.api:getGuildTemplate(code)
	if data then
		return self.state:newGuildTemplate(data)
	else
		return nil, err
	end
end

function Client:deleteInvite(code)
	code = checkType('string', code)
	local data, err = self.api:deleteInvite(code)
	if data then
		return true -- 200
	else
		return false, err
	end
end

function Client:createDM(userId)
	userId = checkSnowflake(userId)
	local data, err = self.api:createDM {recipient_id = userId}
	if data then
		return self.state:newChannel(data)
	else
		return nil, err
	end
end

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

function Client:getGatewayStatistics()
	local stats = {
		namedEvents = {},
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
		for k, v in pairs(shard.namedEvents) do
			stats.namedEvents[k] = (stats.namedEvents[k] or 0) + v
		end
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

function get:defaultAllowedMentions()
	return readOnly(self._defaultAllowedMentions)
end

function get:defaultBitrate()
	return self._defaultBitrate
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

function get:user()
	return self._user
end

return Client
