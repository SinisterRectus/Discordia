local API = require('./API')
local Socket = require('./Socket')
local Cache = require('../utils/Cache')
local Emitter = require('../utils/Emitter')
local Invite = require('../containers/Invite')
local User = require('../containers/snowflakes/User')
local Guild = require('../containers/snowflakes/Guild')
local PrivateChannel = require('../containers/snowflakes/channels/PrivateChannel')
local pp = require('pretty-print')

local open = io.open
local format = string.format
local colorize = pp.colorize
local traceback = debug.traceback
local date, time, exit = os.date, os.time, os.exit
local wrap, yield, running = coroutine.wrap, coroutine.yield, coroutine.running

local defaultOptions = {
	routeDelay = 300,
	globalDelay = 10,
	messageLimit = 100,
	largeThreshold = 100,
	fetchMembers = false,
	autoReconnect = true,
}

local Client, property, method, cache = class('Client', Emitter)
Client.__description = "The main point of entry into a Discordia application."

function Client:__init(customOptions)
	Emitter.__init(self)
	if customOptions then
		local options = {}
		for k, v in pairs(defaultOptions) do
			if customOptions[k] ~= nil then
				options[k] = customOptions[k]
			else
				options[k] = v
			end
		end
		self._options = options
	else
		self._options = defaultOptions
	end
	self._api = API(self)
	self._socket = Socket(self)
	self._users = Cache({}, User, 'id', self)
	self._guilds = Cache({}, Guild, 'id', self)
	self._private_channels = Cache({}, PrivateChannel, 'id', self)
end

function Client:__tostring()
	if self._user then
		return 'instance of Client for ' .. self._user._username
	else
		return 'instance of Client'
	end
end

local function log(message, color)
	return print(colorize(color, format('%s - %s', date(), message)))
end

function Client:warning(message)
	if self._listeners['warning'] then return self:emit('warning', message) end
	return log(message, 'highlight')
end

function Client:error(message)
	if self._listeners['error'] then return self:emit('error', message) end
	log(traceback(running(), message, 2), 'failure')
	return exit()
end

local function getToken(self, email, password)
	self:warning('Email login is discouraged, use token login instead')
	local success, data = self._api:getToken({email = email, password = password})
	if success then
		if data.token then
			return data.token
		elseif data.mfa then
			self:error('MFA login is not supported')
		end
	else
		self:error(data.email and data.email[1] or data.password and data.password[1])
	end
end

local function run(self, a, b)
	return wrap(function()
		local token = not b and a or getToken(self, a, b)
		if not token then return end
		self._api:setToken(token)
		return self:_connectToGateway(token)
	end)()
end

local function stop(self, shouldExit)
	if self._socket then self._socket:disconnect() end
	if shouldExit then exit() end
end

function Client:_connectToGateway(token)

	local gateway, connected
	local filename = 'gateway.cache'
	local file = open(filename, 'r')

	if file then
		gateway = file:read()
		connected = self._socket:connect(gateway)
		file:close()
	end

	if not connected then
		local success1, success2, data = pcall(self._api.getGateway, self._api)
		if success1 and success2 then
			gateway = data.url
			connected = self._socket:connect(gateway)
		end
		file = nil
	end

	if connected then
		if not file then
			file = open(filename, 'w')
			if file then file:write(gateway):close() end
		end
		return self._socket:handlePayloads(token)
	else
		self:error('Cannot connect to gateway: ' .. (gateway and gateway or 'nil'))
	end

end

function Client:_loadUserData(data)
	self._email = data.email
	self._mobile = data.mobile
	self._verified = data.verified
	self._mfa_enabled = data.mfa_enabled
	data.email = nil
	data.mobile = nil
	data.verified = nil
	data.mfa_enabled = nil
end

local function listVoiceRegions(self)
	local success, data = self._api:listVoiceRegions()
	if success then return data end
end

local function createGuild(self, name, region) -- limited use
	return (self._api:createGuild({name = name, region = region}))
end

local function setUsername(self, username)
	local success, data = self._api:modifyCurrentUser({
		avatar = self._user._avatar,
		username = username,
	})
	if success then self._user._username = data.username end
	return success
end

local function setNick(self, guild, nick)
	local success, data = self._api:modifyCurrentUserNickname(guild._id, {
		nick = nick or ''
	})
	if success then guild.me._nick = data.nick end
	return success
end

local function setAvatar(self, avatar)
	local success, data = self._api:modifyCurrentUser({
		avatar = avatar,
		username = self._user._username,
	})
	if success then self._user._avatar = data.avatar end
	return success
end

local function setStatusIdle(self)
	self._idle_since = time() * 1000
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._status = 'idle' end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

local function setStatusOnline(self)
	self._idle_since = nil
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._status = 'online' end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

local function setGameName(self, gameName)
	self._game_name = gameName
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._game = gameName and {name = gameName} end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

local function acceptInviteByCode(self, code)
	local success, data = self._api:acceptInvite(code)
	if success then return Invite(data, self) end
end

local function getInviteByCode(self, code)
	local success, data = self._api:getInvite(code)
	if success then return Invite(data, self) end
end

local function getUserById(self, id)
	local user = self._users:get(id)
	if user then return user end
	local success, data = self._api:getUser(id)
	if success then return self._users:new(data) end
end

-- cache accessors --

-- users --

local function getUserCount(self)
	return self._users._count
end

local function getUsers(self, key, value)
	return self._users:getAll(key, value)
end

local function getUser(self, key, value)
	return self._users:get(key, value)
end

local function findUser(self, predicate)
	return self._users:find(predicate)
end

local function findUsers(self, predicate)
	return self._users:findAll(predicate)
end

-- guilds --

local function getGuildCount(self)
	return self._guilds._count
end

local function getGuilds(self, key, value)
	return self._guilds:getAll(key, value)
end

local function getGuild(self, key, value)
	return self._guilds:get(key, value)
end

local function findGuild(self, predicate)
	return self._guilds:find(predicate)
end

local function findGuilds(self, predicate)
	return self._guilds:findAll(predicate)
end

-- channels --

local function getChannelCount(self)
	local n = self._private_channels._count
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count + guild._voice_channels._count
	end
	return n
end

local function getChannels(self, key, value)
	return wrap(function()
		for channel in self._private_channels:getAll(key, value) do
			yield(channel)
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:getAll(key, value) do
				yield(channel)
			end
			for channel in guild._voice_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end

local function getChannel(self, key, value)
	local channel = self._private_channels:get(key, value)
	if channel then return channel end
	for guild in self._guilds:iter() do
		channel = guild._text_channels:get(key, value) or guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

local function findChannel(self, predicate)
	local channel = self._private_channels:find(predicate)
	if channel then return channel end
	for guild in self._guilds:iter() do
		channel = guild._text_channels:find(predicate) or guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

local function findChannels(self, predicate)
	return wrap(function()
		for channel in self._private_channels:findAll(predicate) do
			yield(channel)
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:findAll(predicate) do
				yield(channel)
			end
			for channel in guild._voice_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- private channels --

local function getPrivateChannelCount(self)
	return self._private_channels._count
end

local function getPrivateChannels(self, key, value)
	return self._private_channels:getAll(key, value)
end

local function getPrivateChannel(self, key, value)
	return self._private_channels:get(key, value)
end

local function findPrivateChannel(self, predicate)
	return self._private_channels:find(predicate)
end

local function findPrivateChannels(self, predicate)
	return self._private_channels:findAll(predicate)
end

-- text channels --

local function getTextChannelCount(self)
	local n = self._private_channels._count
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count
	end
	return n
end

local function getTextChannels(self, key, value)
	return wrap(function()
		for channel in self._private_channels:getAll(key, value) do
			yield(channel)
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end

local function getTextChannel(self, key, value)
	local channel = self._private_channels:get(key, value)
	if channel then return channel end
	for guild in self._guilds:iter() do
		channel = guild._text_channels:get(key, value)
		if channel then return channel end
	end
end

local function findTextChannel(self, predicate)
	local channel = self._private_channels:find(predicate)
	if channel then return channel end
	for guild in self._guilds:iter() do
		channel = guild._text_channels:find(predicate)
		if channel then return channel end
	end
end

local function findTextChannels(self, predicate)
	return wrap(function()
		for channel in self._private_channels:findAll(predicate) do
			yield(channel)
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- guild channels --

local function getGuildChannelCount(self)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count + guild._voice_channels._count
	end
	return n
end

local function getGuildChannels(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:getAll(key, value) do
				yield(channel)
			end
			for channel in guild._voice_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end

local function getGuildChannel(self, key, value)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value) or guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

local function findGuildChannel(self, predicate)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate) or guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

local function findGuildChannels(self, predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:findAll(predicate) do
				yield(channel)
			end
			for channel in guild._voice_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- guild text channels --

local function getGuildTextChannelCount(self)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count
	end
	return n
end

local function getGuildTextChannels(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end

local function getGuildTextChannel(self, key, value)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value)
		if channel then return channel end
	end
end

local function findGuildTextChannel(self, predicate)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate)
		if channel then return channel end
	end
end

local function findGuildTextChannels(self, predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- guild voice channels --

local function getGuildVoiceChannelCount(self)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._voice_channels._count
	end
	return n
end

local function getGuildVoiceChannels(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._voice_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end

local function getGuildVoiceChannel(self, key, value)
	for guild in self._guilds:iter() do
		local channel = guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

local function findGuildVoiceChannel(self, predicate)
	for guild in self._guilds:iter() do
		local channel = guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

local function findGuildVoiceChannels(self, predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._voice_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- roles --

local function getRoleCount(self)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._roles._count
	end
	return n
end

local function getRoles(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for role in guild._roles:getAll(key, value) do
				yield(role)
			end
		end
	end)
end

local function getRole(self, key, value)
	for guild in self._guilds:iter() do
		local role = guild._roles:get(key, value)
		if role then return role end
	end
end

local function findRole(self, predicate)
	for guild in self._guilds:iter() do
		local role = guild._roles:find(predicate)
		if role then return role end
	end
end

local function findRoles(self, predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for role in guild._roles:findAll(predicate) do
				yield(role)
			end
		end
	end)
end

-- members --

local function getMemberCount(self)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._members._count
	end
	return n
end

local function getMembers(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for member in guild._members:getAll(key, value) do
				yield(member)
			end
		end
	end)
end

local function getMember(self, key, value)
	for guild in self._guilds:iter() do
		local member = guild._members:get(key, value)
		if member then return member end
	end
end

local function findMember(self, predicate)
	for guild in self._guilds:iter() do
		local member = guild._members:find(predicate)
		if member then return member end
	end
end

local function findMembers(self, predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for member in guild._members:findAll(predicate) do
				yield(member)
			end
		end
	end)
end

-- messages --

local function getMessageCount(self)
	local n = 0
	for channel in self._private_channels:iter() do
		n = n + channel._messages._count
	end
	for guild in self._guilds:iter() do
		for channel in guild._text_channels:iter() do
			n = n + channel._messages._count
		end
	end
	return n
end

local function getMessages(self, key, value)
	return wrap(function()
		for channel in self._private_channels:iter() do
			for message in channel._messages:getAll(key, value) do
				yield(message)
			end
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:iter() do
				for message in channel._messages:getAll(key, value) do
					yield(message)
				end
			end
		end
	end)
end

local function getMessage(self, key, value)
	for channel in self._private_channels:iter() do
		local message = channel._messages:get(key, value)
		if message then return message end
	end
	for guild in self._guilds:iter() do
		for channel in guild._text_channels:iter() do
			local message = channel._messages:get(key, value)
			if message then return message end
		end
	end
end

local function findMessage(self, predicate)
	for channel in self._private_channels:iter() do
		local message = channel._messages:find(predicate)
		if message then return message end
	end
	for guild in self._guilds:iter() do
		for channel in guild._text_channels:iter() do
			local message = channel._messages:find(predicate)
			if message then return message end
		end
	end
end

local function findMessages(self, predicate)
	return wrap(function()
		for channel in self._private_channels:iter() do
			for message in channel._messages:findAll(predicate) do
				yield(message)
			end
		end
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:iter() do
				for message in channel._messages:findAll(predicate) do
					yield(message)
				end
			end
		end
	end)
end

----

property('user', '_user', nil, 'User', "The User object for the client")
property('email', '_email', nil, 'string', "The client's email address (non-bot only)")
property('mobile', '_mobile', nil, 'boolean', "Whether the client has used a Discord mobile app (non-bot only)")
property('verified', '_verified', nil, 'boolean', "Whether the client account is verified by Discord")
property('mfaEnabled', '_mfa_enabled', nil, 'boolean', "Whether the client has MFA enabled")

method('run', run, 'token', "Connects to a Discord gateway using a valid Discord token and starts the main program loop(s).")
method('stop', stop, 'shouldExit', "Disconnects from the Discord gateway and optionally exits the process.")

method('listVoiceRegions', listVoiceRegions, nil, "Returns a table of voice regions.")
method('createGuild', createGuild, 'name, region', "Creates a guild with the provided name and voice region.")
method('acceptInviteByCode', acceptInviteByCode, 'code', "Accepts a guild invitation with the raw invite code.")
method('getInviteByCode', getInviteByCode, 'code', "Returns an Invite object corresponding to a raw invite code, if it exists.")
method('getUserById', getUserById, 'id', "Returns a user from the client cache or from Discord if it is not cached.")

method('setUsername', setUsername, 'username', "Sets the user's username.")
method('setNickname', setNick, 'guild, nickname', "Sets the user's nickname for the indicated guild.")
method('setAvatar', setAvatar, 'avatar', "Sets the user's avatar. Must be a base64-encoded JPEG.")
method('setStatusIdle', setStatusIdle, nil, "Sets the user status to idle. Warning: This can silently fail!")
method('setStatusOnline', setStatusOnline, nil, "Sets the user status to idle. Warning: This can silently fail!")
method('setGameName', setGameName, 'gameName', "Sets the user's 'now playing' game title. Warning: This can silently fail!")

cache('Guild', getGuildCount, getGuild, getGuilds, findGuild, findGuilds)
cache('User', getUserCount, getUser, getUsers, findUser, findUsers)
cache('Channel', getChannelCount, getChannel, getChannels, findChannel, findChannels)
cache('PrivateChannel', getPrivateChannelCount, getPrivateChannel, getPrivateChannels, findPrivateChannel, findPrivateChannels)
cache('GuildChannel', getGuildChannelCount, getGuildChannel, getGuildChannels, findGuildChannel, findGuildChannels)
cache('TextChannel', getTextChannelCount, getTextChannel, getTextChannels, findTextChannel, findTextChannels)
cache('GuildTextChannel', getGuildTextChannelCount, getGuildTextChannel, getGuildTextChannels, findGuildTextChannel, findGuildTextChannels)
cache('GuildVoiceChannel', getGuildVoiceChannelCount, getGuildVoiceChannel, getGuildVoiceChannels, findGuildVoiceChannel, findGuildVoiceChannels)
cache('VoiceChannel', getGuildVoiceChannelCount, getGuildVoiceChannel, getGuildVoiceChannels, findGuildVoiceChannel, findGuildVoiceChannels)
cache('Role', getRoleCount, getRole, getRoles, findRole, findRoles)
cache('Member', getMemberCount, getMember, getMembers, findMember, findMembers)
cache('Message', getMessageCount, getMessage, getMessages, findMessage, findMessages)

return Client
