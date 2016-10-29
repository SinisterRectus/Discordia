local timer = require('timer')
local Cache = require('../utils/Cache')
local Stopwatch = require('../utils/Stopwatch')
local User = require('../containers/snowflakes/User')
local Guild = require('../containers/snowflakes/Guild')
local PrivateTextChannel = require('../containers/snowflakes/channels/PrivateTextChannel')

local insert, concat, keys = table.insert, table.concat, table.keys
local info, warning, failure = console.info, console.warning, console.failure

local ignore = {
	'MESSAGE_ACK',
	'CHANNEL_PINS_UPDATE',
	'GUILD_EMOJIS_UPDATE',
	'MESSAGE_REACTION_ADD',
	'MESSAGE_REACTION_REMOVE',
}

local function checkReady(client)
	for k, v in pairs(client.loading) do
		if next(v) then
			return client.stopwatch:restart()
		end
	end
	client.loading = nil
	client.stopwatch = nil
	return client:emit('ready')
end

local EventHandler = {}

function EventHandler.READY(data, client)

	client.loading = {guilds = {}, chunks = {}, syncs = {}}

	client.sessionId = data.session_id
	client.users = Cache({}, User, 'id', client)
	client.user = client.users:new(data.user)
	client.user:_loadClientData(data.user)

	client.guilds = Cache(data.guilds, Guild, 'id', client)
	client.privateChannels = Cache(data.private_channels, PrivateTextChannel, 'id', client)

	if client.user.bot then
		client.api.headers['Authorization'] = 'Bot ' .. client.api.headers['Authorization']
		for guild in client.guilds:iter() do
			client.loading.guilds[guild.id] = true
		end
	else
		local guildIds = {}
		for guild in client.guilds:iter() do
			local id = guild.id
			client.loading.syncs[id] = true
			insert(guildIds, id)
		end
		client.socket:syncGuilds(guildIds)
	end

	client.stopwatch = Stopwatch()
	checkReady(client)

	if not client.loading then return end

	local interval
	interval = timer.setInterval(1000, function()
		local loading = client.loading
		if not loading then
			return timer.clearInterval(interval)
		end
		if client.stopwatch:getSeconds() < 10 then return end
		if next(loading.syncs) then
			local ids = concat(keys(loading.syncs), ', ')
			failure('Client failed to sync guild(s): ' .. ids)
		end
		if next(loading.guilds) then
			local ids = concat(keys(loading.guilds), ', ')
			warning('Client initiated with unavailable guild(s): ' .. ids)
		end
		if next(loading.chunks) then
			local ids = concat(keys(loading.chunks), ', ')
			warning('Client may lack offline member data for guild(s): ' .. ids)
		end
		client.loading = nil
		client.stopwatch = nil
		return client:emit('ready')
	end)

end

function EventHandler.RESUMED(data, client)
	return client:emit('resumed')
end

function EventHandler.CHANNEL_CREATE(data, client)
	local channel
	if data.is_private then
		channel = client.privateChannels:new(data)
	else
		local guild = client.guilds:get(data.guild_id)
		if not guild then return warning.cache('guild', 'CHANNEL_CREATE') end
		if data.type == 'text' then
			channel = guild.textChannels:new(data)
		elseif data.type == 'voice' then
			channel = guild.voiceChannels:new(data)
		end
	end
	return client:emit('channelCreate', channel)
end

function EventHandler.CHANNEL_UPDATE(data, client)
	local channel -- private channels should never update
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'CHANNEL_UPDATE') end
	if data.type == 'text' then
		channel = guild.textChannels:get(data.id)
		if not channel then return warning.cache('text channel', 'CHANNEL_UPDATE') end
	elseif data.type == 'voice' then
		channel = guild.voiceChannels:get(data.id)
		if not channel then return warning.cache('voice channel', 'CHANNEL_UPDATE') end
	end
	channel:_update(data)
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(data, client)
	local channel
	if data.is_private then
		channel = client.privateChannels:get(data.id)
		if not channel then return warning.cache('private channel', 'CHANNEL_DELETE') end
		client.privateChannels:remove(channel)
	else
		local guild = client.guilds:get(data.guild_id)
		if not guild then return warning.cache('guild', 'CHANNEL_DELETE') end
		if data.type == 'text' then
			channel = guild.textChannels:get(data.id)
			if not channel then return warning.cache('text channel', 'CHANNEL_DELETE') end
			guild.textChannels:remove(channel)
		elseif data.type == 'voice' then
			channel = guild.voiceChannels:get(data.id)
			if not channel then return warning.cache('voice channel', 'CHANNEL_DELETE') end
			guild.voiceChannels:remove(channel)
		end
	end
	return client:emit('channelDelete', channel)
end

function EventHandler.GUILD_CREATE(data, client)
	local guild = client.guilds:get(data.id)
	if guild then
		if guild.unavailable and not data.unavailable then
			guild:_makeAvailable(data)
			if client.loading then
				client.loading.guilds[guild.id] = nil
				checkReady(client)
			end
			return client:emit('guildAvailable', guild)
		else
			return warning('Erroneous guild availability on GUILD_CREATE')
		end
	else
		guild = client.guilds:new(data)
		if guild.unavailable then
			return client:emit('unavailableGuildCreate', guild)
		else
			return client:emit('guildCreate', guild)
		end
	end
end

function EventHandler.GUILD_UPDATE(data, client)
	local guild = client.guilds:get(data.id)
	if not guild then return warning.cache('guild', 'GUILD_UPDATE') end
	guild:_update(data)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(data, client)
	local guild = client.guilds:get(data.id)
	if not guild then return warning.cache('guild', 'GUILD_DELETE') end
	if data.unavailable then
		guild.unavailable = true
		return client:emit('guildUnavailable', guild)
	else
		client.guilds:remove(guild)
		return client:emit('guildDelete', guild)
	end
end

function EventHandler.GUILD_BAN_ADD(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_BAN_ADD') end
	local user = client.users:get(data.user.id) or client.users:new(data)
	return client:emit('userBan', user, guild)
end

function EventHandler.GUILD_BAN_REMOVE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_BAN_REMOVE') end
	local user = client.users:get(data.user.id) or client.users:new(data)
	return client:emit('userUnban', user, guild)
end

function EventHandler.GUILD_MEMBER_ADD(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_MEMBER_ADD') end
	local member = guild.members:new(data)
	guild.memberCount = guild.memberCount + 1
	return client:emit('memberJoin', member)
end

function EventHandler.GUILD_MEMBER_REMOVE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_MEMBER_REMOVE') end
	local member = guild.members:get(data.user.id)
	if not member then return warning.cache('member', 'GUILD_MEMBER_REMOVE') end
	guild.members:remove(member)
	guild.memberCount = guild.memberCount - 1
	return client:emit('memberLeave', member)
end

function EventHandler.GUILD_MEMBER_UPDATE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_MEMBER_UPDATE') end
	local member = guild.members:get(data.user.id)
	if not member then return warning.cache('member', 'GUILD_MEMBER_UPDATE') end
	member:_update(data)
	return client:emit('memberUpdate', member)
end

function EventHandler.GUILD_MEMBERS_CHUNK(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_MEMBER_CHUNK') end
	guild.members:merge(data.members)
	if client.loading and guild.memberCount == guild.members.count then
		client.loading.chunks[guild.id] = nil
		checkReady(client)
	end
end

function EventHandler.GUILD_ROLE_CREATE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_ROLE_CREATE') end
	local role = guild.roles:new(data.role)
	return client:emit('roleCreate', role)
end

function EventHandler.GUILD_ROLE_UPDATE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_ROLE_UPDATE') end
	local role = guild.roles:get(data.role.id)
	if not role then return warning.cache('role', 'GUILD_ROLE_UPDATE') end
	role:_update(data.role)
	return client:emit('roleUpdate', role)
end

function EventHandler.GUILD_ROLE_DELETE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'GUILD_ROLE_DELETE') end
	local role = guild.roles:get(data.role_id)
	if not role then return warning.cache('role', 'GUILD_ROLE_DELETE') end
	guild.roles:remove(role)
	return client:emit('roleDelete', role)
end

function EventHandler.GUILD_SYNC(data, client)
	local guild = client.guilds:get(data.id)
	if not guild then return warning.cache('guild', 'GUILD_SYNC') end
	guild.members:merge(data.members)
	guild:_loadMemberPresences(data.presences)
	guild.large = data.large
	if guild.large and client.options.fetchMembers then
		guild:requestMembers()
	end
	if client.loading then
		client.loading.syncs[guild.id] = nil
		checkReady(client)
	end
end

function EventHandler.MESSAGE_CREATE(data, client)
	local channel = client:getTextChannelById(data.channel_id) -- shortcut required
	if not channel then return warning.cache('channel', 'MESSAGE_CREATE') end
	local message = channel.messages:new(data)
	return client:emit('messageCreate', message)
end

function EventHandler.MESSAGE_UPDATE(data, client)
	local channel = client:getTextChannelById(data.channel_id) -- shortcut required
	if not channel then return warning.cache('channel', 'MESSAGE_UPDATE') end
	local message = channel.messages:get(data.id)
	if not message then return warning.cache('message', 'MESSAGE_UPDATE') end
	message:_update(data)
	return client:emit('messageUpdate', message)
end

function EventHandler.MESSAGE_DELETE(data, client)
	local channel = client:getTextChannelById(data.channel_id) -- shortcut required
	if not channel then return warning.cache('channel', 'MESSAGE_DELETE') end
	local message = channel.messages:get(data.id)
	if not message then return warning.cache('message', 'MESSAGE_DELETE') end
	channel.messages:remove(message)
	return client:emit('messageDelete', message)
end

function EventHandler.MESSAGE_DELETE_BULK(data, client)
	local channel = client:getTextChannelById(data.channel_id) -- shortcut required
	if not channel then return warning.cache('channel', 'MESSAGE_DELETE_BULK') end
	local messages = {}
	for _, id in ipairs(data.ids) do
		local message = channel.messages:get(id)
		if not message then
			warning.cache('message', 'MESSAGE_DELETE_BULK')
		else
			client:emit('messageDelete', message)
		end
	end
end

function EventHandler.PRESENCE_UPDATE(data, client)
	if not data.guild_id then return end -- friend update
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'PRESENCE_UPDATE') end
	local member = guild:_updateMemberPresence(data)
	if not member then return warning.cache('member', 'PRESENCE_UPDATE') end
	return client:emit('presenceUpdate', member)
end

function EventHandler.TYPING_START(data, client)
	local channel = client:getTextChannelById(data.channel_id) -- shortcut required
	if not channel then return warning.cache('channel', 'TYPING_START') end
	local user = client.users:get(data.user_id)
	if not user then return warning.cache('user', 'TYPING_START') end
	return client:emit('typingStart', user, channel, data.timestamp)
end

function EventHandler.USER_UPDATE(data, client)
	client.user:_update(data)
	return client:emit('userUpdate', client.user)
end

function EventHandler.VOICE_STATE_UPDATE(data, client)
	local guild = client.guilds:get(data.guild_id)
	if not guild then return warning.cache('guild', 'VOICE_STATE_UPDATE') end
	local voiceState = guild.voiceStates:get(data.session_id)
	if voiceState then
		if data.channel_id then
			voiceState:_update(data)
			return client:emit('voiceUpdate', voiceState)
		else
			guild.voiceStates:remove(voiceState)
			return client:emit('voiceLeave', voiceState)
		end
	else
		voiceState = guild.voiceStates:new(data)
		return client:emit('voiceJoin', voiceState)
	end
end

for _, event in ipairs(ignore) do
	EventHandler[event] = function() return end
end

return EventHandler
