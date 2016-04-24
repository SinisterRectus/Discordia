local md5 = require('md5')
local json = require('json')
local http = require('coro-http')
local timer = require('timer')
local utils = require('./utils')
local events = require('./events')
local package = require('./package')
local endpoints = require('./endpoints')

local Error = require('./classes/utils/error')
local Invite = require('./classes/discord/invite')
local Server = require('./classes/discord/server')
local Warning = require('./classes/utils/warning')
local WebSocket = require('./classes/utils/websocket')

local camelify = utils.camelify

local Client = require('core').Emitter:extend()

function Client:initialize(email, password)

	self.servers = {}
	self.maxMessages = 100 -- per channel
	self.privateChannels = {}

	self.headers = {
		['Content-Type'] = 'application/json',
		['User-Agent'] = string.format('DiscordBot (%s, %s)', package.homepage, package.version)
	}

end

-- overwrite original emit method to make it non-blocking
local emit = Client.emit
local wrappedEmit = function(self, name, ...)
	return emit(self, name, ...)
end

function Client:emit(name, ...)
	return coroutine.wrap(wrappedEmit)(self, name, ...)
end

function Client:run(email, password)
	return coroutine.wrap(function()
		self:login(email, password)
		self:websocketConnect()
	end)()
end

-- Authentication --

function Client:login(email, password)

	local token
	local filename = md5.sumhexa(email) .. '.cache'
	local cache = io.open(filename, 'r')
	if not cache then
		token = self:getToken(email, password)
		io.open(filename, 'w'):write(token):close()
	else
		token = cache:read()
	end

	self.headers['Authorization'] = token
	self.token = token

end

function Client:logout()
	local body = {token = self.token}
	self:request('POST', {endpoints.logout}, body)
end

function Client:getToken(email, password)
	local body = {email = email, password = password}
	return self:request('POST', {endpoints.login}, body).token
end

-- HTTP --

function Client:request(method, url, body)

	if type(url) == 'table' then
		url = table.concat(url, '/')
	end

	local headers = {}
	for k, v in pairs(self.headers) do
		table.insert(headers, {k, v})
	end

	local encodedBody
	if body then
		encodedBody = json.encode(body)
		table.insert(headers, {'Content-Length', encodedBody:len()})
	end

	local res, data = http.request(method, url, headers, encodedBody)

	if res.code == 403 then -- forbidden
		return self:emit('error', Error('Forbidden request attempted. Check client permissions.', debug.traceback()))
	elseif res.code == 429 then -- too many requests
		local delay
		for _, header in ipairs(res) do
			if header[1] == 'Retry-After' then
				delay = header[2]
				break
			end
		end
		self:emit('warning', Warning(string.format('Too many requests, retrying in %i ms', delay)))
		timer.sleep(delay)
		return self:request(method, url, body)
	end

	local obj = json.decode(data)
	return camelify(obj)

end

-- WebSocket --

function Client:getGateway()
	return self:request('GET', {endpoints.gateway}).url
end

function Client:websocketConnect()

	local gateway
	local filename ='gateway.cache'
	local cache = io.open(filename, 'r')
	if not cache then
		gateway = self:getGateway()
		io.open(filename, 'w'):write(gateway):close()
	else
		gateway = cache:read()
	end

	self.websocket = WebSocket(gateway)
	self.websocket:identify(self.token)

	self:websocketReceiver()

end

function Client:websocketReceiver()

	return coroutine.wrap(function()
		while true do
			local payload = self.websocket:receive()
			-- if payload then
				if payload.op == 0 then
					self.sequence = payload.s
					self:emit('raw', payload)
					local event = camelify(payload.t)
					local data = camelify(payload.d)
					if not events[event] then error('Unhandled event ' .. event) end
					events[event](data, self)
				else
					error('Unhandled payload ' .. payload.op)
				end
			-- else
				-- timer.sleep(5000)
				-- return self:websocketConnect()
			-- end
		end
	end)()
	-- need to handle websocket disconnection

end

function Client:keepAliveHandler(interval)

	return coroutine.wrap(function(interval)
		while true do
			timer.sleep(interval)
			self.websocket:heartbeat(self.sequence)
		end
	end)(interval)
	-- need to handle websocket disconnection

end

-- Profile --

function Client:setUsername(newUsername, password)
	local body = {
		avatar = self.user.avatar,
		email = self.email,
		username = newUsername,
		password = password
	}
	self:request('PATCH', {endpoints.me}, body)
end

function Client:setAvatar(newAvatar, password)
	local body = {
		avatar = newAvatar, -- base64
		email = self.email,
		username = self.user.username,
		password = password
	}
	self:request('PATCH', {endpoints.me}, body)
end

function Client:setEmail(newEmail, password)
	local body = {
		avatar = self.user.avatar,
		email = newEmail,
		username = self.user.username,
		password = password
	}
	self:request('PATCH', {endpoints.me}, body)
end

function Client:setPassword(newPassword, password)
	local body = {
		avatar = self.user.avatar,
		email = self.email,
		username = self.user.username,
		password = password,
		new_password = newPassword
	}
	self:request('PATCH', {endpoints.me}, body)
end

function Client:setStatusIdle()
	self.idleSince = os.time()
	self.websocket:statusUpdate(self.idleSince, self.user.gameName)
end

function Client:setStatusOnline()
	self.idleSince = nil
	self.websocket:statusUpdate(self.idleSince, self.user.gameName)
end

function Client:setGameName(gameName)
	self.websocket:statusUpdate(self.idleSince, gameName)
end

-- Invites --

function Client:acceptInviteByCode(code)
	local body = {validate = code}
	return self:request('POST', {endpoints.invites, code}, body)
end

-- Servers --

function Client:createServer(name, regionId)
	local body = {name = name, region = regionId}
	local data = self:request('POST', {endpoints.servers}, body)
	return Server(data, self) -- not the same object that is cached
end

function Client:getServerById(id)
	return self.servers[id]
end

function Client:getServerByName(name)
	for _, server in pairs(self.servers) do
		if server.name == name then
			return server
		end
	end
	return nil
end

function Client:getRegions()
	return self:request('GET', {endpoints.voice, 'regions'})
end

-- Channels --

function Client:getChannelById(id) -- Server:getChannelById(id)
	local privateChannel = self.privateChannels[id]
	if privateChannel then return privateChannel end
	for _, server in pairs(self.servers) do
		local channel = server.channels[id]
		if channel then return channel end
	end
	return nil
end

function Client:getChannelByName(name) -- Server:getChannelByName(name)
	for _, channel in pairs(self.privateChannels) do
		if channel.name == name then
			return channel
		end
	end
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.name == name then
				return channel
			end
		end
	end
	return nil
end

-- Members --

function Client:getMemberById(id) -- Server:getMemberById(id)
	for _, server in pairs(self.servers) do
		local member = server.members[id]
		if member then return member end
	end
	return nil
end

function Client:getMemberByName(name) -- Server:getMemberByName(name)
	for _, server in pairs(self.servers) do
		local member = server.members[id]
		for _, member in pairs(server.members) do
			if member.username == name then
				return member
			end
		end
	end
	return nil
end

-- Roles --

function Client:getRoleById(id) -- Server:getRoleById(id)
	for _, server in pairs(self.servers) do
		local role = server.roles[id]
		if role then return role end
	end
	return nil
end

function Client:getRoleByName(name) -- Server:getRoleByName(name)
	for _, server in pairs(self.servers) do
		for _, role in pairs(server.roles) do
			if role.name == name then
				return role
			end
		end
	end
	return nil
end

-- Messages --

function Client:getMessageById(id) -- Server:getMessageById(id), Channel:getMessageById(id)
	for _, channel in pairs(self.privateChannels) do
		local message = channel.messages[id]
		if message then return end
	end
	for _, server in pairs(self.servers) do
		for _, channel in pairs(server.channels) do
			if channel.type == 'text' then
				local message = channel.messages[id]
				if message then return message end
			end
		end
	end
	return nil
end

return Client
