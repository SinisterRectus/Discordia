local fs = require('fs')
local json = require('json')

local constants = require('constants')
local enums = require('enums')
local package = require('../../package.lua')

local API = require('client/API')
local Shard = require('client/Shard')
local Resolver = require('client/Resolver')

local GroupChannel = require('containers/GroupChannel')
local Guild = require('containers/Guild')
local PrivateChannel = require('containers/PrivateChannel')
local User = require('containers/User')
local Invite = require('containers/Invite')
local Webhook = require('containers/Webhook')
local Relationship = require('containers/Relationship')

local Cache = require('iterables/Cache')
local WeakCache = require('iterables/WeakCache')
local Emitter = require('utils/Emitter')
local Logger = require('utils/Logger')
local Mutex = require('utils/Mutex')

local encode, decode, null = json.encode, json.decode, json.null
local readFileSync, writeFileSync = fs.readFileSync, fs.writeFileSync

local logLevel = enums.logLevel
local gameType = enums.gameType

local wrap = coroutine.wrap
local time, difftime = os.time, os.difftime
local format = string.format

local CACHE_AGE = constants.CACHE_AGE

-- do not change these options here
-- pass a custom table on client construction instead
local defaultOptions = {
	routeDelay = 300,
	maxRetries = 5,
	shardCount = 0,
	firstShard = 0,
	lastShard = -1,
	largeThreshold = 100,
	cacheAllMembers = false,
	autoReconnect = true,
	compress = true,
	bitrate = 64000,
	logFile = 'discordia.log',
	logLevel = logLevel.info,
	dateTime = '%F %T',
	syncGuilds = false,
}

local function parseOptions(customOptions)
	if type(customOptions) == 'table' then
		local options = {}
		for k, default in pairs(defaultOptions) do -- load options
			local custom = customOptions[k]
			if custom ~= nil then
				options[k] = custom
			else
				options[k] = default
			end
		end
		for k, v in pairs(customOptions) do -- validate options
			local default = type(defaultOptions[k])
			local custom = type(v)
			if default ~= custom then
				return error(format('invalid client option %q (%s expected, got %s)', k, default, custom), 3)
			end
			if custom == 'number' and (v < 0 or v % 1 ~= 0) then
				return error(format('invalid client option %q (number must be a positive integer)', k), 3)
			end
		end
		return options
	else
		return defaultOptions
	end
end

local Client, get = require('class')('Client', Emitter)

function Client:__init(options)
	Emitter.__init(self)
	options = parseOptions(options)
	self._options = options
	self._shards = {}
	self._api = API(self)
	self._mutex = Mutex()
	self._users = Cache({}, User, self)
	self._guilds = Cache({}, Guild, self)
	self._group_channels = Cache({}, GroupChannel, self)
	self._private_channels = Cache({}, PrivateChannel, self)
	self._relationships = Cache({}, Relationship, self)
	self._webhooks = WeakCache({}, Webhook, self) -- used for audit logs
	self._logger = Logger(options.logLevel, options.dateTime, options.logFile)
	self._role_map = {}
	self._emoji_map = {}
	self._channel_map = {}
end

for name, level in pairs(logLevel) do
	Client[name] = function(self, fmt, ...)
		local msg = self._logger:log(level, fmt, ...)
		return self:emit(name, msg or format(fmt, ...))
	end
end

local function run(self, token)

	self:info('Discordia %s', package.version)
	self:info('Connecting to Discord...')

	local api = self._api
	local users = self._users
	local options = self._options

	local user, err1 = api:authenticate(token)
	if not user then
		return self:error('Could not authenticate, check token: ' .. err1)
	end
	self._user = users:_insert(user)

	self:info('Authenticated as %s#%s', user.username, user.discriminator)

	local now = time()
	local url, count, owner

	local cache = readFileSync('gateway.json')
	cache = cache and decode(cache)

	if cache then
		local d = cache[user.id]
		if d and difftime(now, d.timestamp) < CACHE_AGE then
			url = cache.url
			if user.bot then
				count = d.shards
				owner = d.owner
			else
				count = 1
				owner = user
			end
		end
	else
		cache = {}
	end

	if not url or not owner then

		if user.bot then

			local gateway, err2 = api:getGatewayBot()
			if not gateway then
				return self:error('Could not get gateway: ' .. err2)
			end

			local app, err3 = api:getCurrentApplicationInformation()
			if not app then
				return self:error('Could not get application information: ' .. err3)
			end

			url = gateway.url
			count = gateway.shards
			owner = app.owner

			cache[user.id] = {owner = owner, shards = count, timestamp = now}

		else

			local gateway, err2 = api:getGateway()
			if not gateway then
				return self:error('Could not get gateway: ' .. err2)
			end

			url = gateway.url
			count = 1
			owner = user

			cache[user.id] = {timestamp = now}

		end

		cache.url = url

		writeFileSync('gateway.json', encode(cache))

	end

	self._owner = users:_insert(owner)

	if options.shardCount > 0 then
		if count ~= options.shardCount then
			self:warning('Requested shard count (%i) is different from recommended count (%i)', options.shardCount, count)
		end
		count = options.shardCount
	end

	local first, last = options.firstShard, options.lastShard

	if last < 0 then
		last = count - 1
	end

	if last < first then
		return self:error('First shard ID (%i) is greater than last shard ID (%i)', first, last)
	end

	local d = last - first + 1
	if d > count then
		return self:error('Shard count (%i) is less than target shard range (%i)', count, d)
	end

	if first == last then
		self:info('Launching shard %i (%i out of %i)...', first, d, count)
	else
		self:info('Launching shards %i through %i (%i out of %i)...', first, last, d, count)
	end

	self._total_shard_count = count
	self._shard_count = last - first

	for id = first, last do
		self._shards[id] = Shard(id, self)
	end

	for _, shard in pairs(self._shards) do
		wrap(shard.connect)(shard, url, token)
		shard:identifyWait()
	end

end

function Client:run(token, presence)
	self._presence = presence or {}
	return wrap(run)(self, token)
end

function Client:stop()
	for _, shard in pairs(self._shards) do
		shard:disconnect()
	end
end

function Client:_modify(payload)
	local data, err = self._api:modifyCurrentUser(payload)
	if data then
		data.token = nil
		self._user:_load(data)
		return true
	else
		return false, err
	end
end

function Client:setUsername(username)
	return self:_modify({username = username or null})
end

function Client:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or null})
end

function Client:createGuild(name)
	local data, err = self._api:createGuild({name = name})
	if data then
		return true
	else
		return false, err
	end
end

function Client:createGroupChannel()
	local data, err = self._api:createGroupDM()
	if data then
		return self._group_channels:_insert(data)
	else
		return nil, err
	end
end

function Client:getWebhook(id)
	local data, err = self._api:getWebhook(id)
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

function Client:getInvite(code)
	local data, err = self._api:getInvite(code)
	if data then
		return Invite(data, self)
	else
		return nil, err
	end
end

function Client:getUser(id)
	id = Resolver.userId(id)
	local user = self._users:get(id)
	if user then
		return user
	else
		local data, err = self._api:getUser(id)
		if data then
			return self._users:_insert(data)
		else
			return nil, err
		end
	end
end

function Client:getGuild(id)
	id = Resolver.guildId(id)
	return self._guilds:get(id)
end

function Client:getChannel(id)
	id = Resolver.channelId(id)
	local guild = self._channel_map[id]
	if guild then
		return guild._text_channels:get(id) or guild._voice_channels:get(id) or guild._categories:get(id)
	else
		return self._private_channels:get(id) or self._group_channels:get(id)
	end
end

function Client:listVoiceRegions()
	return self._api:listVoiceRegions()
end

function Client:getConnections()
	return self._api:getUsersConnections()
end

local function updateStatus(self)
	local presence = self._presence
	presence.afk = presence.afk or null
	presence.game = presence.game or null
	presence.since = presence.since or null
	presence.status = presence.status or null
	for _, shard in pairs(self._shards) do
		shard:updateStatus(presence)
	end
end

function Client:setStatus(status)
	if type(status) == 'string' then
		self._presence.status = status
		if status == 'idle' then
			self._presence.since = 1000 * time()
		else
			self._presence.since = null
		end
	else
		self._presence.status = null
		self._presence.since = null
	end
	return updateStatus(self)
end

function Client:setGame(game)
	if type(game) == 'string' then
		game = {name = game, type = gameType.default}
	elseif type(game) == 'table' then
		if type(game.name) == 'string' then
			if type(game.type) ~= 'number' then
				if type(game.url) == 'string' then
					game.type = gameType.streaming
				else
					game.type = gameType.default
				end
			end
		else
			game = null
		end
	else
		game = null
	end
	self._presence.game = game
	return updateStatus(self)
end

function Client:setAFK(afk)
	if type(afk) == 'boolean' then
		self._presence.afk = afk
	else
		self._presence.afk = null
	end
	return updateStatus(self)
end

function get.shardCount(self)
	return self._shard_count
end

function get.totalShardCount(self)
	return self._total_shard_count
end

function get.user(self)
	return self._user
end

function get.owner(self)
	return self._owner
end

function get.verified(self)
	return self._user and self._user._verified
end

function get.mfaEnabled(self)
	return self._user and self._user._verified
end

function get.email(self)
	return self._user and self._user._email
end

function get.guilds(self)
	return self._guilds
end

function get.users(self)
	return self._users
end

function get.privateChannels(self)
	return self._private_channels
end

function get.groupChannels(self)
	return self._group_channels
end

function get.relationships(self)
	return self._relationships
end

return Client
