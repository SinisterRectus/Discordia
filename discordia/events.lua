local User = require('./classes/user')
local Role = require('./classes/role')
local Member = require('./classes/member')
local Server = require('./classes/server')
local Message = require('./classes/message')
local VoiceState = require('./classes/voicestate')
local PrivateChannel = require('./classes/privatechannel')
local ServerTextChannel = require('./classes/servertextchannel')
local ServerVoiceChannel = require('./classes/servervoicechannel')

local events = {}

function events.ready(data, client)

	client.user = User(data.user, client) -- object
	client.email = data.user.email -- string
	client.verified = data.user.verified -- boolean

	for _, serverData in ipairs(data.guilds) do
		local server = Server(serverData, client)
		client.servers[server.id] = server
	end

	for _, privateChannelData in ipairs(data.privateChannels) do
		local privateChannel = PrivateChannel(privateChannelData, client)
		client.privateChannels[privateChannel.id] = privateChannel
	end

	client:keepAliveHandler(data.heartbeatInterval)

	client:emit('ready')

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
	if not server then return end -- probably "unavailable"
	local member = server:getMemberById(data.user.id)
	if not member then return end -- invalid user, probably large server
	member:update(data)
	client:emit('presenceUpdate', user)

end

function events.userUpdate(data, client)

	client.user:update(data, client)
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
	elseif voiceState.channelId then
		voiceState:update(data)
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
	if channel.deque:size() > client.maxMessages then
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

	if not message then
		local channel = client:getChannelById(data.channelId)
		message = Message(data, channel)
		channel.messages[message.id] = message
	else
		message:update(data)
	end

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
		local channel = client:getPrivateChannelById(data.id)
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
	channel:update(data)
	client:emit('channelUpdate', channel)

end

function events.guildBanAdd(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	client:emit('memberBan', member)

end

function events.guildBanRemove(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	client:emit('memberUnban', member)

end

function events.guildCreate(data, client)

	if data.unavailable then return end
	local server = Server(data, client)
	client.servers[server.id] = server
	client:emit('serverCreate', server)

end

function events.guildDelete(data, client)

	if data.unavailable then return end
	local server = client:getServerById(data.id)
	client.servers[server.id] = nil
	client:emit('serverDelete', server)

end

function events.guildUpdate(data, client)

	local server = client:getServerById(data.id)
	server:update(data)
	client:emit('serverUpdate', server)

end

function events.guildIntegrationsUpdate(data, client)
	-- unhandled for now
end

function events.guildMemberAdd(data, client)

	local server = client:getServerById(data.guildId)
	local member = Member(data, server)
	server.members[member.id] = member
	server.memberCount = server.memberCount + 1
	client:emit('memberJoin', member)

end

function events.guildMemberRemove(data, client)

	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	server.members[member.id] = nil
	server.memberCount = server.memberCount - 1
	client:emit('memberLeave', member)

end

function events.guildMemberUpdate(data, client)

	-- I think this is only for role updates
	local server = client:getServerById(data.guildId)
	local member = server:getMemberById(data.user.id)
	member.roles = data.roles
	client:emit('memberUpdate', member)

end

function events.guildMembersChunk(data, client)

	local server = client:getServerById(data.guildId)

	for _, memberData in ipairs(data.members) do
		local member = Member(memberData, server)
		server.members[member.id] = member
	end

	client:emit('membersChunk', server)

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
	role:update(data)
	client:emit('roleUpdate', role)

end

return events
