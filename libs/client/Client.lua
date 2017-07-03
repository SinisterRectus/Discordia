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

local Cache = require('iterables/Cache')
local WeakCache = require('iterables/WeakCache')
local Emitter = require('utils/Emitter')
local Logger = require('utils/Logger')
local Mutex = require('utils/Mutex')

local encode, decode = json.encode, json.decode
local readFileSync, writeFileSync = fs.readFileSync, fs.writeFileSync

local logLevel = enums.logLevel

local wrap = coroutine.wrap
local time, difftime = os.time, os.difftime
local format = string.format

local CACHE_AGE = constants.CACHE_AGE

local defaultOptions = {
	routeDelay = 300,
	maxRetries = 5,
	shardCount = 0,
	messageLimit = 100,
	largeThreshold = 100,
	fetchMembers = false,
	autoReconnect = true,
	compress = true,
	bitrate = 64000,
	logFile = 'discordia.log',
	logLevel = logLevel.info,
	dateTime = '%F %T',
	gateway = true,
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
			if v == 'number' and (v < 0 or v % 1 ~= 0) then
				return error(format('invalid client option %q (number must be a positive integer)', k), 3)
			end
		end
		return options
	else
		return defaultOptions
	end
end

local Client = require('class')('Client', Emitter)
local get = Client.__getters

function Client:__init(options)
	Emitter.__init(self)
	options = parseOptions(options)
	self._options = options
	self._shards = {}
	self._api = API(self)
	self._mutex = Mutex()
	self._users = WeakCache(User, self)
	self._guilds = Cache(Guild, self)
	self._group_channels = Cache(GroupChannel, self)
	self._private_channels = Cache(PrivateChannel, self)
	self._logger = Logger(options.logLevel, options.dateTime, options.logFile)
	self._channel_map = {}
end

for _, name in ipairs({'error', 'warning', 'info', 'debug'}) do
	local level = logLevel[name]
	Client[name] = function(self, fmt, ...)
		local msg = self._logger:log(level, fmt, ...)
		if #self._listeners[name] > 0 then
			return self:emit(name, msg or format(fmt, ...))
		end
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

	-- if user.bot then -- TODO: activate on release
	-- 	local app, err2 = api:getCurrentApplicationInformation()
	-- 	if not app then
	-- 		return self:error('Could not get application information: ' .. err2)
	-- 	end
	-- 	self._owner = users:_insert(app.owner)
	-- else
	-- 	self._owner = self._user
	-- end

	self:info('Authenticated as %s#%s', user.username, user.discriminator)

	if not options.gateway then -- TODO: maybe remove until rest mode is sorted out
		return self:emit('ready')
	end

	local url, shard_count

	local cache = readFileSync('gateway.json')
	cache = cache and decode(cache)

	if cache then
		local d = cache[user.id]
		if d and difftime(time(), d.timestamp) < CACHE_AGE then
			url, shard_count = cache.url, d.shards or 1
		end
	else
		cache = {}
	end

	if not url then
		local d = user.bot and api:getGatewayBot() or api:getGateway()
		if d then
			url, shard_count = d.url, d.shards or 1
			cache.url = url
			cache[user.id] = {timestamp = time(), shards = d.shards}
			writeFileSync('gateway.json', encode(cache))
		end
	end

	if not url then
		return self:error('Could not connect to gateway (no URL found)')
	end

	if options.shardCount > 0 then
		shard_count = options.shardCount
	end

	self:info('Shard count: %i', shard_count)
	self._shard_count = shard_count

	for id = 0, shard_count - 1 do
		self._shards[id] = Shard(id, self)
	end

	for _, shard in pairs(self._shards) do
		wrap(shard.connect)(shard, url, token)
		shard:identifyWait()
	end

end

function Client:run(token)
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
	return self:_modify({username = username or json.null})
end

function Client:setAvatar(avatar)
	avatar = Resolver.image(avatar)
	return self:_modify({avatar = avatar or json.null})
end

function Client:createGuild(name)
	local data, err = self._api:createGuild({name = name})
	if data then -- NOTE: incomplete object, wait for GUILD_CREATE
		return true
	else
		return false, err
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

function Client:listVoiceRegions()
	return self._api:listVoiceRegions()
end

function get.shardCount(self)
	return self._shard_count
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

return Client
