local path = './classes/snowflake'
local User = require(path .. '/user')
local Role = require(path .. '/role')
local Member = require(path .. '/member')
local Server = require(path .. '/server')
local Message = require(path .. '/message')
local PrivateChannel = require(path .. '/privatechannel')
local ServerTextChannel = require(path .. '/servertextchannel')
local ServerVoiceChannel = require(path .. '/servervoicechannel')
local VoiceState = require('./classes/voicestate')
local timer = require('timer')

local events = {}

function events.ready(data, client)

	if data.user.bot then
		client.headers['Authorization'] = 'Bot ' .. client.headers['Authorization']
	end

	client.user = User(data.user, client)
	client.email = data.user.email
	client.verified = data.user.verified
	client.sessionId = data.sessionId

	for _, serverData in ipairs(data.guilds) do
		if not serverData.unavailable then
			local server = Server(serverData, client)
			client.servers[server.id] = server
		end
	end

	for _, privateChannelData in ipairs(data.privateChannels) do
		local privateChannel = PrivateChannel(privateChannelData, client)
		client.privateChannels[privateChannel.id] = privateChannel
	end

	client:startKeepAliveHandler(data.heartbeatInterval)

	client.readyInterval = timer.setInterval(1000, function()
		if client.loading then
			client.loading = nil
		else
			timer.clearInterval(client.readyInterval)
			client:emit('ready')
		end
	end)

end

function events.resumed(data, client)

	client:startKeepAliveHandler(data.heartbeatInterval)
	client:emit('resumed')

end

function events.typingStart(data, client)

	local channel = client:getChannelById(data.channelId)
	local user = channel.recipient or channel.server:getMemberById(data.userId)
	client:emit('typingStart', user, channel)

end

function events.presenceUpdate(data, client)

	-- data.roles exists, but not sure if a role change fires presenceUpdate
	-- fires for status update and game update
	-- seems to fire for username/avatar/email changes, too
	-- see guildMemberUpdate for role changes
	local server = client:getServerById(data.guildId)
	if not server then return end
	local member = server:getMemberById(data.user.id)
	if not member then return end
	member:_update(data)
	client:emit('presenceUpdate', member)

end

function events.userUpdate(data, client)

	client.user:_update(data, client)
	client.email = data.email
	client.verified = data.verified
	client:emit('userUpdate', client.user)

end

function events.voiceStateUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local voiceState = server.voiceStates[data.sessionId]

	if not voiceState then
		voiceState = VoiceState(data, server)
		server.voiceStates[voiceState.sessionId] = voiceState
		client:emit('voiceJoin', voiceState)
	elseif data.channelId then
		voiceState:_update(data)
		client:emit('voiceUpdate', voiceState)
	else
		server.voiceStates[voiceState.sessionId] = nil
		client:emit('voiceLeave', voiceState)
	end

end

function events.messageCreate(data, client)

	local channel = client:getChannelById(data.channelId)
	local message = Message(data, channel)
	channel.lastMessageId = message.id
	channel.messages[message.id] = message
	channel.deque:pushRight(message)
	if channel.deque:getCount() > client.maxMessages then
		local msg = channel.deque:popLeft()
		channel.messages[msg.id] = nil
	end
	client:emit('messageCreate', message)

end

function events.messageDelete(data, client)

	local message = client:getMessageById(data.id)
	if not message then return end
	message.channel.messages[message.id] = nil
	-- deleted messages stay in the deque and contribute to total count
	client:emit('messageDelete', message)

end

function events.messageUpdate(data, client)

	local message = client:getMessageById(data.id)
	if not message then return end
	message:_update(data)
	client:emit('messageUpdate', message)

end

function events.messageAck(data, client)

	local channel = client:getChannelById(data.channelId)
	local message = channel:getMessageById(data.messageId)
	client:emit('messageAcknowledge', message)

end

function events.channelCreate(data, client)

	local channel
	if data.isPrivate then
		channel = PrivateChannel(data, client)
		client.privateChannels[channel.id] = channel
	else
		local server = client:getServerById(data.guildId)
		if data.type == 'text' then
			channel = ServerTextChannel(data, server)
		elseif data.type == 'voice' then
			channel = ServerVoiceChannel(data, server)
		end
		server.channels[channel.id] = channel
	end
	client:emit('channelCreate', channel)

end

function events.channelDelete(data, client)

	if data.isPrivate then
		local channel = client:getChannelById(data.id)
		client.privateChannels[channel.id] = nil
	else
		local server = client:getServerById(data.guildId)
		local channel = server:getChannelById(data.id)
		server.channels[channel.id] = nil
	end
	client:emit('channelDelete', channel)

end

function events.channelUpdate(data, client)

	-- can private channels update?
	local server = client:getServerById(data.guildId)
	local channel = client:getChannelById(data.guildId)
	channel:_update(data)
	client:emit('channelUpdate', channel)

end

function events.guildBanAdd(data, client)

	-- might want to change to userBan
	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id) or User(data.user, client)
	client:emit('memberBan', member)

end

function events.guildBanRemove(data, client)

	-- might want to change to userUnban
	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id) or User(data.user, client)
	client:emit('memberUnban', member)

end

function events.guildCreate(data, client)

	local server = Server(data, client)
	client.servers[server.id] = server
	client:emit('serverCreate', server)

	if client.readyInterval then
		client.waiting = true
	end

end

function events.guildDelete(data, client)

	if data.unavailable then return end
	local server = client:getServerById(data.id)
	client.servers[server.id] = nil
	client:emit('serverDelete', server)

end

function events.guildUpdate(data, client)

	local server = client:getServerById(data.id)
	server:_update(data)
	client:emit('serverUpdate', server)

end

function events.guildIntegrationsUpdate(data, client)
	-- unhandled for now
end

function events.guildMemberAdd(data, client)

	local server = client:getServerById(data.guildId)
	local member = Member(data, server)
	server.members[member.id] = member
	client:emit('memberJoin', member)

end

function events.guildMemberRemove(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	server.members[member.id] = nil
	client:emit('memberLeave', member)

end

function events.guildMemberUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	member:_update(data)
	client:emit('memberUpdate', member)

end

function events.guildMembersChunk(data, client)

	local server = client:getServerById(data.guildId)

	for _, memberData in ipairs(data.members) do
		local member = server.members[memberData.user.id]
		if not member then
			member = Member(memberData, server)
			server.members[member.id] = member
		end
		member:_update(memberData)
	end

	client:emit('membersChunk', server)

	if client.readyInterval then
		client.loading = true
	end

end

function events.guildRoleCreate(data, client)

	local server = client:getServerById(data.guildId)
	local role = Role(data.role, server)
	server.roles[role.id] = role
	client:emit('roleCreate', role)

end

function events.guildRoleDelete(data, client)

	local server = client:getServerById(data.guildId)
	local role = server:getRoleById(data.roleId)
	server.roles[role.id] = nil
	client:emit('roleDelete', role)

end

function events.guildRoleUpdate(data, client)

	local server = client:getServerById(data.guildId)
	local role = server:getRoleById(data.role.id)
	role:_update(data.role)
	client:emit('roleUpdate', role)

end

return events
