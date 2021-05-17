--[=[
@c Client x Emitter
@t ui
@op options table
@d The main point of entry into a Discordia application. All data relevant to
Discord is accessible through a client instance or its child objects after a
connection to Discord is established with the `run` method. In other words,
client data should not be expected and most client methods should not be called
until after the `ready` event is received. Base emitter methods may be called
at any time. See [[client options]].
]=]

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

local VoiceManager = require('voice/VoiceManager')

local encode, decode, null = json.encode, json.decode, json.null
local readFileSync, writeFileSync = fs.readFileSync, fs.writeFileSync

local logLevel = enums.logLevel
local gameType = enums.gameType

local wrap = coroutine.wrap
local time, difftime = os.time, os.difftime
local format = string.format

local CACHE_AGE = constants.CACHE_AGE
local GATEWAY_VERSION = constants.GATEWAY_VERSION

-- do not change these options here
-- pass a custom table on client initialization instead
local defaultOptions = {
	routeDelay = 250,
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
	gatewayFile = 'gateway.json',
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
	self._voice = VoiceManager(self)
	self._role_map = {}
	self._emoji_map = {}
	self._channel_map = {}
	self._events = require('client/EventHandler')
end

for name, level in pairs(logLevel) do
	Client[name] = function(self, fmt, ...)
		local msg = self._logger:log(level, fmt, ...)
		return self:emit(name, msg or format(fmt, ...))
	end
end

function Client:_deprecated(clsName, before, after)
	local info = debug.getinfo(3)
	return self:warning(
		'%s:%s: %s.%s is deprecated; use %s.%s instead',
		info.short_src,
		info.currentline,
		clsName,
		before,
		clsName,
		after
	)
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
	self._token = token

	self:info('Authenticated as %s#%s', user.username, user.discriminator)

	local now = time()
	local url, count, owner

	local cache = readFileSync(options.gatewayFile)
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

		writeFileSync(options.gatewayFile, encode(cache))

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
	self._shard_count = d

	for id = first, last do
		self._shards[id] = Shard(id, self)
	end

	local path = format('/?v=%i&encoding=json', GATEWAY_VERSION)
	for _, shard in pairs(self._shards) do
		wrap(shard.connect)(shard, url, path)
		shard:identifyWait()
	end

end

--[=[
@m run
@p token string
@op presence table
@r nil
@d Authenticates the current user via HTTPS and launches as many WSS gateway
shards as are required or requested. By using coroutines that are automatically
managed by Luvit libraries and a libuv event loop, multiple clients per process
and multiple shards per client can operate concurrently. This should be the last
method called after all other code and event handlers have been initialized. If
a presence table is provided, it will act as if the user called `setStatus`
and `setGame` after `run`.
]=]
function Client:run(token, presence)
	self._presence = presence or {}
	return wrap(run)(self, token)
end

--[=[
@m stop
@t ws
@r nil
@d Disconnects all shards and effectively stops their loops. This does not
empty any data that the client may have cached.
]=]
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

--[=[
@m setUsername
@t http
@p username string
@r boolean
@d Sets the client's username. This must be between 2 and 32 characters in
length. This does not change the application name.
]=]
function Client:setUsername(username)
	return self:_modify({username = username or null})
end

--[=[
@m setAvatar
@t http
@p avatar Base64-Resolvable
@r boolean
@d Sets the client's avatar. To remove the avatar, pass an empty string or nil.
This does not change the application image.
]=]
function Client:setAvatar(avatar)
	avatar = avatar and Resolver.base64(avatar)
	return self:_modify({avatar = avatar or null})
end

--[=[
@m createGuild
@t http
@p name string
@r boolean
@d Creates a new guild. The name must be between 2 and 100 characters in length.
This method may not work if the current user is in too many guilds. Note that
this does not return the created guild object; wait for the corresponding
`guildCreate` event if you need the object.
]=]
function Client:createGuild(name)
	local data, err = self._api:createGuild({name = name})
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m createGroupChannel
@t http
@r GroupChannel
@d Creates a new group channel. This method is only available for user accounts.
]=]
function Client:createGroupChannel()
	local data, err = self._api:createGroupDM()
	if data then
		return self._group_channels:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m getWebhook
@t http
@p id string
@r Webhook
@d Gets a webhook object by ID. This always makes an HTTP request to obtain a
static object that is not cached and is not updated by gateway events.
]=]
function Client:getWebhook(id)
	local data, err = self._api:getWebhook(id)
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

--[=[
@m getInvite
@t http
@p code string
@op counts boolean
@r Invite
@d Gets an invite object by code. This always makes an HTTP request to obtain a
static object that is not cached and is not updated by gateway events.
]=]
function Client:getInvite(code, counts)
	local data, err = self._api:getInvite(code, counts and {with_counts = true})
	if data then
		return Invite(data, self)
	else
		return nil, err
	end
end

--[=[
@m getUser
@t http?
@p id User-ID-Resolvable
@r User
@d Gets a user object by ID. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made. Under circumstances
which should be rare, the user object may be an old version, not updated by
gateway events.
]=]
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

--[=[
@m getGuild
@t mem
@p id Guild-ID-Resolvable
@r Guild
@d Gets a guild object by ID. The current user must be in the guild and the client
must be running the appropriate shard that serves this guild. This method never
makes an HTTP request to obtain a guild.
]=]
function Client:getGuild(id)
	id = Resolver.guildId(id)
	return self._guilds:get(id)
end

--[=[
@m getChannel
@t mem
@p id Channel-ID-Resolvable
@r Channel
@d Gets a channel object by ID. For guild channels, the current user must be in
the channel's guild and the client must be running the appropriate shard that
serves the channel's guild.

For private channels, the channel must have been previously opened and cached.
If the channel is not cached, `User:getPrivateChannel` should be used instead.
]=]
function Client:getChannel(id)
	id = Resolver.channelId(id)
	local guild = self._channel_map[id]
	if guild then
		return guild._text_channels:get(id) or guild._voice_channels:get(id) or guild._categories:get(id)
	else
		return self._private_channels:get(id) or self._group_channels:get(id)
	end
end

--[=[
@m getRole
@t mem
@p id Role-ID-Resolvable
@r Role
@d Gets a role object by ID. The current user must be in the role's guild and
the client must be running the appropriate shard that serves the role's guild.
]=]
function Client:getRole(id)
	id = Resolver.roleId(id)
	local guild = self._role_map[id]
	return guild and guild._roles:get(id)
end

--[=[
@m getEmoji
@t mem
@p id Emoji-ID-Resolvable
@r Emoji
@d Gets an emoji object by ID. The current user must be in the emoji's guild and
the client must be running the appropriate shard that serves the emoji's guild.
]=]
function Client:getEmoji(id)
	id = Resolver.emojiId(id)
	local guild = self._emoji_map[id]
	return guild and guild._emojis:get(id)
end

--[=[
@m listVoiceRegions
@t http
@r table
@d Returns a raw data table that contains a list of voice regions as provided by
Discord, with no formatting beyond what is provided by the Discord API.
]=]
function Client:listVoiceRegions()
	return self._api:listVoiceRegions()
end

--[=[
@m getConnections
@t http
@r table
@d Returns a raw data table that contains a list of connections as provided by
Discord, with no formatting beyond what is provided by the Discord API.
This is unrelated to voice connections.
]=]
function Client:getConnections()
	return self._api:getUsersConnections()
end

--[=[
@m getApplicationInformation
@t http
@r table
@d Returns a raw data table that contains information about the current OAuth2
application, with no formatting beyond what is provided by the Discord API.
]=]
function Client:getApplicationInformation()
	return self._api:getCurrentApplicationInformation()
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

--[=[
@m setStatus
@t ws
@p status string
@r nil
@d Sets the current user's status on all shards that are managed by this client.
See the `status` enumeration for acceptable status values.
]=]
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

--[=[
@m setGame
@t ws
@p game string/table
@r nil
@d Sets the current user's game on all shards that are managed by this client.
If a string is passed, it is treated as the game name. If a table is passed, it
must have a `name` field and may optionally have a `url` or `type` field. Pass `nil` to
remove the game status.
]=]
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

--[=[
@m setAFK
@t ws
@p afk boolean
@r nil
@d Set the current user's AFK status on all shards that are managed by this client.
This generally applies to user accounts and their push notifications.
]=]
function Client:setAFK(afk)
	if type(afk) == 'boolean' then
		self._presence.afk = afk
	else
		self._presence.afk = null
	end
	return updateStatus(self)
end

--[=[@p shardCount number/nil The number of shards that this client is managing.]=]
function get.shardCount(self)
	return self._shard_count
end

--[=[@p totalShardCount number/nil The total number of shards that the current user is on.]=]
function get.totalShardCount(self)
	return self._total_shard_count
end

--[=[@p user User/nil User object representing the current user.]=]
function get.user(self)
	return self._user
end

--[=[@p owner User/nil User object representing the current user's owner.]=]
function get.owner(self)
	return self._owner
end

--[=[@p verified boolean/nil Whether the current user's owner's account is verified.]=]
function get.verified(self)
	return self._user and self._user._verified
end

--[=[@p mfaEnabled boolean/nil Whether the current user's owner's account has multi-factor (or two-factor)
authentication enabled. This is equivalent to `verified`]=]
function get.mfaEnabled(self)
	return self._user and self._user._verified
end

--[=[@p email string/nil The current user's owner's account's email address (user-accounts only).]=]
function get.email(self)
	return self._user and self._user._email
end

--[=[@p guilds Cache An iterable cache of all guilds that are visible to the client. Note that the
guilds present here correspond to which shards the client is managing. If all
shards are managed by one client, then all guilds will be present.]=]
function get.guilds(self)
	return self._guilds
end

--[=[@p users Cache An iterable cache of all users that are visible to the client.
To access a user that may exist but is not cached, use `Client:getUser`.]=]
function get.users(self)
	return self._users
end

--[=[@p privateChannels Cache An iterable cache of all private channels that are visible to the client. The
channel must exist and must be open for it to be cached here. To access a
private channel that may exist but is not cached, `User:getPrivateChannel`.]=]
function get.privateChannels(self)
	return self._private_channels
end

--[=[@p groupChannels Cache An iterable cache of all group channels that are visible to the client. Only
user-accounts should have these.]=]
function get.groupChannels(self)
	return self._group_channels
end

--[=[@p relationships Cache An iterable cache of all relationships that are visible to the client. Only
user-accounts should have these.]=]
function get.relationships(self)
	return self._relationships
end

return Client
