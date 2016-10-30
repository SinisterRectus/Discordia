local core = require('core')
local API = require('./API')
local Socket = require('./Socket')
local Cache = require('../utils/Cache')
local Invite = require('../containers/Invite')
local User = require('../containers/snowflakes/User')
local Guild = require('../containers/snowflakes/Guild')
local PrivateTextChannel = require('../containers/snowflakes/channels/PrivateTextChannel')

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

local Client = core.Emitter:extend()

getmetatable(Client).__call = function(self, ...)
	return self:new(...)
end

function Client:initialize(customOptions)
	if customOptions then
		local options = {}
		for k, v in pairs(defaultOptions) do
			options[k] = customOptions[k] or defaultOptions[k]
		end
		self.options = options
	else
		self.options = defaultOptions
	end
	self.api = API(self)
	self.socket = Socket(self)
	self.users = Cache({}, User, 'id', self)
	self.guilds = Cache({}, Guild, 'id', self)
	self.privateChannels = Cache({}, PrivateTextChannel, 'id', self)
end

Client.meta.__tostring = function(self)
	if self.user then
		return 'instance of Client for ' .. self.user.username
	else
		return 'instance of Client'
	end
end

-- overwrite emit method to make it non-blocking
-- original code copied from core.lua
function Client:emit(name, ...)
	local handlers = rawget(self, 'handlers')
	if not handlers then return end
	local namedHandlers = rawget(handlers, name)
	if not namedHandlers then return end
	for i = 1, #namedHandlers do
		local handler = namedHandlers[i]
		if handler then wrap(handler)(...) end
	end
	for i = #namedHandlers, 1, -1 do
		if not namedHandlers[i] then
			remove(namedHandlers, i)
		end
	end
end

function Client:run(a, b)
	return wrap(function()
		if b then
			self:loginWithEmail(a, b)
		else
			self:loginWithToken(a)
		end
		return self:connectWebSocket()
	end)()
end

function Client:stop(exit)
	if self.socket then self.socket:disconnect() end
	if exit then os.exit() end
end

function Client:loginWithEmail(email, password)
	warning('Email login is discouraged, use token login instead')
	local success, data = self.api:getToken({email = email, password = password})
	if not data.token then
		failure(data.email and data.email[1] or data.password and data.password[1])
	end
	return self:loginWithToken(data.token)
end

function Client:loginWithToken(token)
	self.token = token
	return self.api:setToken(token)
end

function Client:connectWebSocket()

	local gateway, connected
	local filename = 'gateway.cache'
	local cache = open(filename, 'r')

	if cache then
		gateway = cache:read()
		connected = self.socket:connect(gateway)
		cache:close()
	end

	if not connected then
		local success, data = self.api:getGateway()
		if success then
			gateway = data.url
			connected = self.socket:connect(gateway)
		end
		cache = nil
	end

	if connected then
		if not cache then
			cache = open(filename, 'w')
			if cache then cache:write(gateway):close() end
		end
		return wrap(self.socket.handlePayloads)(self.socket)
	else
		return failure('Bad gateway: ' .. (gateway and gateway or 'nil'))
	end

end

function Client:listVoiceRegions()
	local success, data = self.api:listVoiceRegions()
	if success then return data end
end

function Client:createGuild(name, region) -- limited use
	local success, data = self.api:createGuild({name = name, region = region})
	return success
end

function Client:setUsername(username)
	local success, data = self.api:modifyCurrentUser({
		avatar = self.user.avatar,
		email = self.user.email,
		username = username,
	})
	if success then self.user.username = data.username end
	return success
end

function Client:setNickname(guild, nickname)
	local success, data = self.api:modifyCurrentUserNickname(guild.id, {
		nick = nickname or ''
	})
	if success then guild.me.nick = data.nick end
	return success
end

function Client:setAvatar(avatar)
	local success, data = self.api:modifyCurrentUser({
		avatar = avatar,
		email = self.user.email,
		username = self.user.username,
	})
	if success then self.user.avatar = data.avatar end
	return success
end

function Client:setStatusIdle()
	self.idleSince = time() * 1000
	local id = self.user.id
	for guild in self:getGuilds() do
		local me = guild.members:get(id)
		me.status = 'idle'
	end
	return self.socket:statusUpdate(self.idleSince, self.gameName)
end

function Client:setStatusOnline()
	self.idleSince = nil
	local id = self.user.id
	for guild in self:getGuilds() do
		local me = guild.members:get(id)
		me.status = 'online'
	end
	return self.socket:statusUpdate(self.idleSince, self.gameName)
end

function Client:setGameName(gameName)
	self.gameName = gameName
	local id = self.user.id
	for guild in self:getGuilds() do
		local me = guild.members:get(id)
		me.gameName = gameName
	end
	return self.socket:statusUpdate(self.idleSince, self.gameName)
end

function Client:acceptInviteByCode(code)
	local success, data = self.api:acceptInvite(code)
	return success
end

function Client:getInviteByCode(code)
	local success, data = self.api:getInvite(code)
	if success then return Invite(data, self) end
end

function Client:getPrivateChannelById(id)
	return self.privateChannels:get(id)
end

function Client:getUserById(id)
	local user = self.users:get(id)
	if not user then
		local success, data = self.api:getUser(id)
		if success then user = self.users:new(data) end
	end
	return user
end

function Client:getUserByName(username)
	return self.users:get('username', username)
end

function Client:getGuildById(id)
	return self.guilds:get(id)
end

function Client:getGuildByName(name)
	return self.guilds:get('name', name)
end

function Client:getChannelById(id)
	return self:getPrivateChannelById(id) or self:getGuildChannelById(id) or nil
end

function Client:getTextChannelById(id)
	return self:getPrivateChannelById(id) or self:getGuildTextChannelById(id) or nil
end

function Client:getGuildChannelById(id)
	for guild in self:getGuilds() do
		local channel = guild:getChannelById(id)
		if channel then return channel end
	end
end

function Client:getGuildTextChannelById(id)
	for guild in self:getGuilds() do
		local channel = guild:getTextChannelById(id)
		if channel then return channel end
	end
end

function Client:getGuildVoiceChannelById(id)
	for guild in self:getGuilds() do
		local channel = guild:getVoiceChannelById(id)
		if channel then return channel end
	end
end

function Client:getGuildRoleById(id)
	for guild in self:getGuilds() do
		local role = guild:getRoleById(id)
		if role then return role end
	end
end

function Client:getPrivateChannels()
	return self.privateChannels:iter()
end

function Client:getGuilds()
	return self.guilds:iter()
end

function Client:getUsers()
	return self.users:iter()
end

function Client:getChannels()
	return wrap(function()
		for channel in self:getPrivateChannels() do
			yield(channel)
		end
		for guild in self:getGuilds() do
			for channel in guild:getChannels() do
				yield(channel)
			end
		end
	end)
end

function Client:getTextChannels()
	return wrap(function()
		for channel in self:getPrivateChannels() do
			yield(channel)
		end
		for guild in self:getGuilds() do
			for channel in guild:getTextChannels() do
				yield(channel)
			end
		end
	end)
end

function Client:getGuildChannels()
	return wrap(function()
		for guild in self:getGuilds() do
			for channel in guild:getChannels() do
				yield(channel)
			end
		end
	end)
end

function Client:getGuildTextChannels()
	return wrap(function()
		for guild in self:getGuilds() do
			for channel in guild:getTextChannels() do
				yield(channel)
			end
		end
	end)
end

function Client:getGuildVoiceChannels()
	return wrap(function()
		for guild in self:getGuilds() do
			for channel in guild:getVoiceChannels() do
				yield(channel)
			end
		end
	end)
end

function Client:getGuildRoles()
	return wrap(function()
		for guild in self:getGuilds() do
			for role in guild:getRoles() do
				yield(role)
			end
		end
	end)
end

function Client:getGuildMembers()
	return wrap(function()
		for guild in self:getGuilds() do
			for member in guild:getMembers() do
				yield(member)
			end
		end
	end)
end

Client.getRoles = Client.getGuildRoles
Client.getMembers = Client.getGuildMembers
Client.getVoiceChannels = Client.getGuildVoiceChannels
Client.getRoleById = Client.getGuildRoleById
Client.getVoiceChannelById = Client.getGuildVoiceChannelById
Client.setNick = Client.setNickname

return Client
