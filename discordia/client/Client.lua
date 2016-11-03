local API = require('./API')
local Socket = require('./Socket')
local Cache = require('../utils/Cache')
local Emitter = require('../utils/Emitter')
local Invite = require('../containers/Invite')
local User = require('../containers/snowflakes/User')
local Guild = require('../containers/snowflakes/Guild')
local PrivateChannel = require('../containers/snowflakes/channels/PrivateChannel')

local info, warning, failure = console.info, console.warning, console.failure

local open = io.open
local time = os.time
local remove = table.remove
local wrap, yield = coroutine.wrap, coroutine.yield

local defaultOptions = {
	routeDelay = 300,
	globalDelay = 10,
	messageLimit = 100,
	largeThreshold = 100,
	fetchMembers = false,
}

local Client, property = class('Client', Emitter)

function Client:__init(customOptions)
	Emitter.__init(self)
	if customOptions then
		local options = {}
		for k, v in pairs(defaultOptions) do
			options[k] = customOptions[k] or defaultOptions[k]
		end
		self._options = options
	else
		self._options = defaultOptions
	end
	self._api = API(self)
	self._socket = Socket(self)
	self._users = Cache({}, User, '_id', self)
	self._guilds = Cache({}, Guild, '_id', self)
	self._private_channels = Cache({}, PrivateChannel, '_id', self)
end

property('user', '_user', nil, 'User', "The User object for the client")
property('email', '_email', nil, 'string', "The client's email address (non-bot only)")
property('verified', '_verified', nil, 'boolean', "Whether the client account is verified by Discord")
property('mfaEnabled', '_mfa_enabled', nil, 'boolean', "Whether the client has MFA enabled")

function Client:__tostring()
	if self._user then
		return 'instance of Client for ' .. self._user._username
	else
		return 'instance of Client'
	end
end

local function getToken(self, email, password)
	warning('Email login is discouraged, use token login instead')
	local success, data = self._api:getToken({email = email, password = password})
	if success then
		if data.token then
			return data.token
		elseif data.mfa then
			failure('MFA login is not supported')
		end
	else
		failure(data.email and data.email[1] or data.password and data.password[1])
	end
end

function Client:run(a, b)
	return wrap(function()
		local token = not b and a or getToken(self, a, b)
		self._api:setToken(token)
		return self:_connectToGateway(token)
	end)()
end

function Client:stop(exit)
	if self._socket then self._socket:disconnect() end
	if exit then os.exit() end
end

function Client:_connectToGateway(token)

	local gateway, connected
	local filename = 'gateway.cache'
	local cache = open(filename, 'r')

	if cache then
		gateway = cache:read()
		connected = self._socket:connect(gateway)
		cache:close()
	end

	if not connected then
		local success1, success2, data = pcall(self._api.getGateway, self._api)
		if success1 and success2 then
			gateway = data.url
			connected = self._socket:connect(gateway)
		end
		cache = nil
	end

	if connected then
		if not cache then
			cache = open(filename, 'w')
			if cache then cache:write(gateway):close() end
		end
		return wrap(self._socket.handlePayloads)(self._socket, token)
	else
		failure('Cannot connect to gateway: ' .. (gateway and gateway or 'nil'))
	end

end

function Client:_loadUserData(data)
	self._email = data.email
	self._verified = data.verified
	self._mfa_enabled = data.mfa_enabled
end

function Client:listVoiceRegions()
	local success, data = self._api:listVoiceRegions()
	if success then return data end
end

function Client:createGuild(name, region) -- limited use
	local success, data = self._api:createGuild({name = name, region = region})
	return success
end

function Client:setUsername(username)
	local success, data = self._api:modifyCurrentUser({
		avatar = self._user._avatar,
		email = self._user._email,
		username = username,
	})
	if success then self._user._username = data.username end
	return success
end

function Client:setNick(guild, nick)
	local success, data = self._api:modifyCurrentUserNickname(guild._id, {
		nick = nick or ''
	})
	if success then guild.me._nick = data.nick end
	return success
end

function Client:setAvatar(avatar)
	local success, data = self._api:modifyCurrentUser({
		avatar = avatar,
		email = self._user._email,
		username = self._user._username,
	})
	if success then self._user._avatar = data.avatar end
	return success
end

function Client:setStatusIdle()
	self._idle_since = time() * 1000
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._status = 'idle' end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

function Client:setStatusOnline()
	self._idle_since = nil
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._status = 'online' end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

function Client:setGameName(gameName)
	self._game_name = gameName
	local id = self._user._id
	for guild in self._guilds:iter() do
		local me = guild._members:get(id)
		if me then me._game = gameName and {name = gameName} end
	end
	return self._socket:statusUpdate(self._idle_since, self._game_name)
end

function Client:acceptInviteByCode(code)
	local success, data = self._api:acceptInvite(code)
	return success
end

function Client:getInviteByCode(code)
	local success, data = self._api:getInvite(code)
	if success then return Invite(data, self) end
end

-- cache accessors --

-- users --

property('userCount', function(self, key, value)
	return self._users._count
end, nil, 'number', "How many Users are cached for the client")

property('users', function(self, key, value)
	return self._users:getAll(key, value)
end, nil, 'function', "Iterator for the Users cached for the client")

function Client:getUser(key, value)
	return self._users:get(key, value)
end

function Client:findUser(predicate)
	return self._users:find(predicate)
end

function Client:findUsers(predicate)
	return self._users:findAll(predicate)
end

-- guilds --

property('guildCount', function(self, key, value)
	return self._guilds._count
end, nil, 'number', "How many Guilds are cached for the client")

property('guilds', function(self, key, value)
	return self._guilds:getAll(key, value)
end, nil, 'function', "Iterator for the Guilds cached for the client")

function Client:getGuild(key, value)
	return self._guilds:get(key, value)
end

function Client:findGuild(predicate)
	return self._guilds:find(predicate)
end

function Client:findGuilds(predicate)
	return self._guilds:findAll(predicate)
end

-- channels --

property('channelCount', function(self, key, value)
	local n = self._private_channels._count
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count + guild._voice_channels._count
	end
	return n
end, nil, 'number', "How many Channels are cached for the client")

property('channels', function(self, key, value)
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
end, nil, 'function', "Iterator for the Channels cached for the client")

function Client:getChannel(key, value)
	local channel = self._private_channels:get(key, value)
	if channel then return channel end
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value) or guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

function Client:findChannel(predicate)
	local channel = self._private_channels:find(predicate)
	if channel then return channel end
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate) or guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

function Client:findChannels(predicate)
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

property('privateChannelCount', function(self, key, value)
	return self._private_channels._count
end, nil, 'number', "How many PrivateChannels are cached for the client")

property('privateChannels', function(self, key, value)
	return self._private_channels:getAll(key, value)
end, nil, 'function', "Iterator for the PrivateChannels cached for the client")

function Client:getPrivateChannel(key, value)
	return self._private_channels:get(key, value)
end

function Client:findPrivateChannel(predicate)
	return self._private_channels:find(predicate)
end

function Client:findPrivateChannels(predicate)
	return self._private_channels:findAll(predicate)
end

-- text channels --

property('textChannelCount', function(self, key, value)
	local n = self._private_channels._count
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count
	end
	return n
end, nil, 'number', "How many TextChannels are cached for the client")

property('textChannels', function(self, key, value)
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
end, nil, 'function', "Iterator for the TextChannels cached for the client")

function Client:getTextChannel(key, value)
	local channel = self._private_channels:get(key, value)
	if channel then return channel end
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value)
		if channel then return channel end
	end
end

function Client:findTextChannel(predicate)
	local channel = self._private_channels:find(predicate)
	if channel then return channel end
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate)
		if channel then return channel end
	end
end

function Client:findTextChannels(predicate)
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

property('guildChannelCount', function(self, key, value)
	local n = self._private_channels._count
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count + guild._voice_channels._count
	end
	return n
end, nil, 'number', "How many GuildChannels are cached for the client")

property('guildChannels', function(self, key, value)
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
end, nil, 'function', "Iterator for the GuildChannels cached for the client")

function Client:getGuildChannel(key, value)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value) or guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

function Client:findGuildChannel(predicate)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate) or guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

function Client:findGuildChannels(predicate)
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

property('guildTextChannelCount', function(self, key, value)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._text_channels._count
	end
	return n
end, nil, 'number', "How many GuildTextChannels are cached for the client")

property('guildTextChannels', function(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end, nil, 'function', "Iterator for the GuildTextChannels cached for the client")

function Client:getGuildTextChannel(key, value)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:get(key, value)
		if channel then return channel end
	end
end

function Client:findGuildTextChannel(predicate)
	for guild in self._guilds:iter() do
		local channel = guild._text_channels:find(predicate)
		if channel then return channel end
	end
end

function Client:findGuildTextChannels(predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._text_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- guild voice channels --

property('guildVoiceChannelCount', function(self, key, value)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + guild._voice_channels._count
	end
	return n
end, nil, 'number', "How many GuildVoiceChannels are cached for the client")

property('guildVoiceChannels', function(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._voice_channels:getAll(key, value) do
				yield(channel)
			end
		end
	end)
end, nil, 'function', "Iterator for the GuildVoiceChannels cached for the client")

function Client:getGuildVoiceChannel(key, value)
	for guild in self._guilds:iter() do
		local channel = guild._voice_channels:get(key, value)
		if channel then return channel end
	end
end

function Client:findGuildVoiceChannel(predicate)
	for guild in self._guilds:iter() do
		local channel = guild._voice_channels:find(predicate)
		if channel then return channel end
	end
end

function Client:findGuildVoiceChannels(predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for channel in guild._voice_channels:findAll(predicate) do
				yield(channel)
			end
		end
	end)
end

-- roles --

property('roleCount', function(self, key, value)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + self._roles._count
	end
	return n
end, nil, 'number', "How many Roles are cached for the client")

property('roles', function(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for role in self._roles:getAll(key, value) do
				yield(role)
			end
		end
	end)
end, nil, 'function', "Iterator for the Roles cached for the client")

function Client:getRole(key, value)
	for guild in self._guilds:iter() do
		local role = self._roles:get(key, value)
		if role then return role end
	end
end

function Client:findRole(predicate)
	for guild in self._guilds:iter() do
		local role = self._roles:find(predicate)
		if role then return role end
	end
end

function Client:findRoles(predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for role in self._roles:findAll(predicate) do
				yield(role)
			end
		end
	end)
end

-- members --

property('memberCount', function(self, key, value)
	local n = 0
	for guild in self._guilds:iter() do
		n = n + self._members._count
	end
	return n
end, nil, 'number', "How many Members are cached for the client")

property('members', function(self, key, value)
	return wrap(function()
		for guild in self._guilds:iter() do
			for member in self._members:getAll(key, value) do
				yield(member)
			end
		end
	end)
end, nil, 'function', "Iterator for the Members cached for the client")

function Client:getMember(key, value)
	for guild in self._guilds:iter() do
		local member = self._members:get(key, value)
		if member then return member end
	end
end

function Client:findMember(predicate)
	for guild in self._guilds:iter() do
		local member = self._members:find(predicate)
		if member then return member end
	end
end

function Client:findMembers(predicate)
	return wrap(function()
		for guild in self._guilds:iter() do
			for member in self._members:findAll(predicate) do
				yield(role)
			end
		end
	end)
end

-- messages --

property('messageCount', function(self, key, value)
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
end, nil, 'number', "How many Messages are cached for the client")

property('messages', function(self, key, value)
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
end, nil, 'function', "Iterator for the Messages cached for the client")

function Client:getMessage(key, value)
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

function Client:findMessage(predicate)
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

function Client:findMessages(predicate)
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

Client.setNickname = Client.setNick

return Client
