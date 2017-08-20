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
	fetchMembers = false,
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

--[[
@class Client x Emitter
@param [options]: table

The main point of entry into a Discordia application. All data relevant to
Discord are accessible through a client instance or its child objects after a
connection to Discord is established with the `run` method. In other words,
client data should not be expected and most client methods should not be called
until after the `ready` event is received. Base emitter methods may be called
at any time.
]]
function Client:__init(options)
	Emitter.__init(self)
	options = parseOptions(options)
	self._options = options
	self._shards = {}
	self._api = API(self)
	self._mutex = Mutex()
	self._users = WeakCache({}, User, self)
	self._guilds = Cache({}, Guild, self)
	self._group_channels = Cache({}, GroupChannel, self)
	self._private_channels = Cache({}, PrivateChannel, self)
	self._relationships = Cache({}, Relationship, self)
	self._logger = Logger(options.logLevel, options.dateTime, options.logFile)
	self._channel_map = {}
end

for name, level in pairs(logLevel) do
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

	if user.bot then
		local app, err2 = api:getCurrentApplicationInformation()
		if not app then
			return self:error('Could not get application information: ' .. err2)
		end
		self._owner = users:_insert(app.owner)
	else
		self._owner = self._user
	end

	self:info('Authenticated as %s#%s', user.username, user.discriminator)

	local url, count

	local cache = readFileSync('gateway.json')
	cache = cache and decode(cache)

	if cache then
		local d = cache[user.id]
		if d and difftime(time(), d.timestamp) < CACHE_AGE then
			url, count = cache.url, d.shards or 1
		end
	else
		cache = {}
	end

	if not url then
		local d = user.bot and api:getGatewayBot() or api:getGateway()
		if d then
			url, count = d.url, d.shards or 1
			cache.url = url
			cache[user.id] = {timestamp = time(), shards = d.shards}
			writeFileSync('gateway.json', encode(cache))
		end
	end

	if not url then
		return self:error('Could not connect to gateway (no URL found)')
	end

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

	self._shard_count = count
	for id = first, last do
		self._shards[id] = Shard(id, self)
	end

	for _, shard in pairs(self._shards) do
		wrap(shard.connect)(shard, url, token)
		shard:identifyWait()
	end

end

--[[
@method run
@param token: string
@param [presence]: table

Authenticates the current user via HTTPS and launches as many WSS gateway
shards as are required or requested. By using coroutines that are automatically
managed by Luvit libraries and a libuv event loop, multiple clients per process
and multiple shards per client can operate concurrently. This should be the last
method called after all other code and event handlers have been initialized.
]]
function Client:run(token, presence)
	self._presence = presence or {}
	return wrap(run)(self, token)
end

--[[
@method stop
@tags ws

Disconnects all shards and effectively stop their loops. This does not
empty any data that the client may have cached.
]]
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

--[[
@method setUsername
@tags http
@param username: string
@ret boolean

Sets the client's username. This must be between 2 and 32 characters in length.
This does not change the application name.
]]
function Client:setUsername(username)
	return self:_modify({username = username or null})
end

--[[
@method setAvatar
@tags http
@param avatar: Base64 Resolveable
@ret boolean

Sets the client's avatar. To remove the avatar, pass `nil`. This does not change
the application image.
]]
function Client:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or null})
end

--[[
@method createGuild
@tags http
@param name: string
@ret boolean

Creates a new guild. The name must be between 2 and 100 characters in length.
This method may not work if the current user is in too many guilds. Note that
this does not return the created guild object; listen for the corresponding
 `guildCreate` event if you need the object.
]]
function Client:createGuild(name)
	local data, err = self._api:createGuild({name = name})
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method createGroupChannel
@tags http
@ret GroupChannel

Creates a new group channel. This method is only available for user accounts.
]]
function Client:createGroupChannel()
	local data, err = self._api:createGroupDM()
	if data then
		return self._group_channels:_insert(data)
	else
		return nil, err
	end
end

--[[
@method getWebhook
@tags http
@param id: string
@ret Webhook

Gets a webhook object by ID. This always makes an HTTP request to obtain the
object, which is a static copy of the server object; it is not automatically
updated via gateway events.
]]
function Client:getWebhook(id)
	local data, err = self._api:getWebhook(id)
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

--[[
@method getInvite
@tags http
@param code: string
@ret Invite

Gets an invite object by code. This always makes an HTTP request to obtain the
object, which is a static copy of the server object; it is not automatically
updated via gateway events.
]]
function Client:getInvite(code)
	local data, err = self._api:getInvite(code)
	if data then
		return Invite(data, self)
	else
		return nil, err
	end
end

--[[
@method getUser
@tags http
@param id: User ID Resolveable
@ret User

Gets a user object by ID. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made. Under circumstances
which should be rare, the user object may be an old version, not updated by
gateway events.
]]
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

--[[
@method getGuild
@param id: Guild ID Resolveable
@ret Guild

Gets a guild object by ID. The current user must be in the guild and the client
must be running the appropriate shard that serves this guild. This method never
makes an HTTP request to obtain a guild.
]]
function Client:getGuild(id)
	id = Resolver.guildId(id)
	return self._guilds:get(id)
end

--[[
@method getChannel
@param id: Channel ID Resolveable
@ret Channel

Gets a channel object by ID. For guild channels, the current user must be in the
channel's guild and the client must be running the appropriate shard that serves
the channel's guild.

For private channels, the channel must have been previously opened and cached.
If the channel is not cached, `User:getPrivateChannel` should be used instead.
]]
function Client:getChannel(id)
	id = Resolver.channelId(id)
	local guild = self._channel_map[id]
	if guild then
		return guild._text_channels:get(id) or guild._voice_channels:get(id)
	else
		return self._private_channels:get(id) or self._group_channels:get(id)
	end
end

--[[
@method listVoiceRegions
@tags http
@ret table

Returns a raw data table that contains a list of voice regions as provided by
Discord, with no additional parsing.
]]
function Client:listVoiceRegions()
	return self._api:listVoiceRegions()
end

--[[
@method getConnections
@tags http
@ret table

Returns a raw data table that contains a list of connections as provided by
Discord, with no additional parsing.
]]
function Client:getConnections()
	return self._api:getUsersConnections()
end

local function updateStatus(self)
	local shards = self._shards
	local presence = self._presence
	presence.afk = presence.afk or null
	presence.game = presence.game or null
	presence.since = presence.since or null
	presence.status = presence.status or null
	for i = 0, self._shard_count - 1 do
		shards[i]:updateStatus(presence)
	end
end

--[[
@method setStatus
@tags ws
@param status: string

Sets the current users's status on all shards that are managed by this client.
Valid statuses are `online`, `idle`, `dnd`, and `invisible`.
]]
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

--[[
@method setGame
@tags ws
@param game: string|table

Sets the current users's game on all shards that are managed by this client. If
a string is passed, it is treated as the game name. If a table is passed, it
must have a `name` field and may optionally have a `url` field. Pass `nil` to
remove the game status.
]]
function Client:setGame(game)
	if type(game) == 'string' then
		game = {name = game, type = gameType.default}
	elseif type(game) == 'table' then
		if type(game.name) == 'string' then
			if type(game.url) == 'string' then
				game.type = gameType.streaming
			else
				game.type = gameType.default
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

--[[
@method setAFK
@tags ws
@param afk: boolean

Set the current user's AFK status on all shards that are managed by this client.
This generally applies to user accounts and their push notifications.
]]
function Client:setAFK(afk)
	if type(afk) == 'boolean' then
		self._presence.afk = afk
	else
		self._presence.afk = null
	end
	return updateStatus(self)
end

--[[
@property shardCount: number|nil

The number of shards that this client is managing.
]]
function get.shardCount(self)
	return self._shard_count
end

--[[
@property user: User|nil

User object representing the current user.
]]
function get.user(self)
	return self._user
end

--[[
@property owner: User|nil

User object representing the current user's owner.
]]
function get.owner(self)
	return self._owner
end

--[[
@property verified: boolean|nil

Whether the current user's owner's account is verified.
]]
function get.verified(self)
	return self._user and self._user._verified
end

--[[
@property mfaEnabled: boolean|nil

Whether the current user's owner's account has multi-factor (or two-factor)
authentication enabled.
]]
function get.mfaEnabled(self)
	return self._user and self._user._verified
end

--[[
@property email: string|nil

The current user's owner's account's email address (user-accounts only).
]]
function get.email(self)
	return self._user and self._user._email
end

--[[
@property guilds: Cache

An iterable cache of all guilds that are visible to the client. Note that the
guilds present here correspond to which shards the client is managing. If all
shards are managed by one client, then all guilds will be present.
]]
function get.guilds(self)
	return self._guilds
end

--[[
@property user: WeakCache

An iterable weak cache of all users that are visible to the client. Users that
are not referenced elsewhere are eventually garbage collected. To access a user
that may exist but is not cached, use `Client:getUser`.
]]
function get.users(self)
	return self._users
end

--[[
@property privateChannels: Cache

An iterable cache of all private channels that are visible to the client. The
channel must exist and must be open for it to be cached here. To access a
private channel that may exist but is not cached, `User:getPrivateChannel`.
]]
function get.privateChannels(self)
	return self._private_channels
end

--[[
@property groupChannels: Cache

An iterable cache of all group channels that are visible to the client. Only
user-accounts should have these.
]]
function get.groupChannels(self)
	return self._group_channels
end

--[[
@property relationships: Cache

An iterable cache of all relationships that are visible to the client. Only
user-accounts should have these.
]]
function get.relationships(self)
	return self._relationships
end

return Client
