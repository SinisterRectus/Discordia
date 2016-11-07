local timer = require('timer')
local Stopwatch = require('../utils/Stopwatch')

local format = string.format
local insert, concat, keys = table.insert, table.concat, table.keys

local function warning(client, object, event)
	return client:warning(format('Attempted to access uncached %q on %q', object, event))
end

local function checkReady(client)
	for _, v in pairs(client._loading) do
		if next(v) then
			return client._stopwatch:restart()
		end
	end
	client._loading = nil
	client._stopwatch = nil
	return client:emit('ready')
end

local EventHandler = {}

function EventHandler.READY(data, client)

	client._loading = {guilds = {}, chunks = {}, syncs = {}}

	client._socket._session_id = data.session_id -- TODO: maybe move out of EventHandler

	client:_loadUserData(data.user)
	client._user = client._users:new(data.user)

	client._guilds:merge(data.guilds)
	client._private_channels:merge(data.private_channels)

	if client._user._bot then -- TODO: maybe move token parsing out of EventHandler
		client._api._headers['Authorization'] = 'Bot ' .. client._api._headers['Authorization']
		for guild in client._guilds:iter() do
			client._loading.guilds[guild._id] = true
		end
	else
		local guild_ids = {}
		for guild in client._guilds:iter() do
			if not guild.unavailable then
				local id = guild._id
				client._loading.syncs[id] = true
				insert(guild_ids, id)
			end
		end
		client._socket:syncGuilds(guild_ids)
	end

	client._stopwatch = Stopwatch()
	checkReady(client)

	if not client._loading then return end

	local interval
	interval = timer.setInterval(1000, function()
		local loading = client._loading
		if not loading then return timer.clearInterval(interval) end
		if client._stopwatch:getSeconds() < 10 then return end
		if next(loading.syncs) then
			local ids = concat(keys(loading.syncs), ', ')
			client:error('Client failed to sync guild(s): ' .. ids)
		end
		if next(loading.guilds) then
			local ids = concat(keys(loading.guilds), ', ')
			client:warning('Client initiated with unavailable guild(s): ' .. ids)
		end
		if next(loading.chunks) then
			local ids = concat(keys(loading.chunks), ', ')
			client:warning('Client may lack offline member data for guild(s): ' .. ids)
		end
		client._loading = nil
		client._stopwatch = nil
		timer.clearInterval(interval)
		return client:emit('ready')
	end)

end

function EventHandler.RESUMED(_, client)
	return client:emit('resumed')
end

function EventHandler.CHANNEL_CREATE(data, client)
	local channel
	if data.is_private then
		channel = client._private_channels:new(data)
	else
		local guild = client._guilds:get(data.guild_id)
		if not guild then return warning(client, 'guild', 'CHANNEL_CREATE') end
		if data.type == 'text' then
			channel = guild._text_channels:new(data)
		elseif data.type == 'voice' then
			channel = guild._voice_channels:new(data)
		end
	end
	return client:emit('channelCreate', channel)
end

function EventHandler.CHANNEL_UPDATE(data, client)
	local channel -- private channels should never update
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'CHANNEL_UPDATE') end
	if data.type == 'text' then
		channel = guild._text_channels:get(data.id)
		if not channel then return warning(client, 'text channel', 'CHANNEL_UPDATE') end
	elseif data.type == 'voice' then
		channel = guild._voice_channels:get(data.id)
		if not channel then return warning(client, 'voice channel', 'CHANNEL_UPDATE') end
	end
	channel:_update(data)
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(data, client)
	local channel
	if data.is_private then
		channel = client._private_channels:get(data.id)
		if not channel then return warning(client, 'private channel', 'CHANNEL_DELETE') end
		client._private_channels:remove(channel)
	else
		local guild = client._guilds:get(data.guild_id)
		if not guild then return warning(client, 'guild', 'CHANNEL_DELETE') end
		if data.type == 'text' then
			channel = guild._text_channels:get(data.id)
			if not channel then return warning(client, 'text channel', 'CHANNEL_DELETE') end
			guild._text_channels:remove(channel)
		elseif data.type == 'voice' then
			channel = guild._voice_channels:get(data.id)
			if not channel then return warning(client, 'voice channel', 'CHANNEL_DELETE') end
			guild._voice_channels:remove(channel)
		end
	end
	return client:emit('channelDelete', channel)
end

function EventHandler.GUILD_CREATE(data, client)
	local id = data.id
	if not data.unavailable and not client._user._bot then
		if client._loading then
			client._loading.syncs[id] = true
		end
		client._socket:syncGuilds({id})
	end
	local guild = client._guilds:get(id)
	if guild then
		if guild._unavailable and not data.unavailable then
			guild:_makeAvailable(data)
			client:emit('guildAvailable', guild)
		else
			warning(client, 'Erroneous guild availability on GUILD_CREATE')
		end
		if client._loading then
			client._loading.guilds[guild._id] = nil
			checkReady(client)
		end
	else
		guild = client._guilds:new(data)
		if guild._unavailable then
			return client:emit('guildCreateUnavailable', guild)
		else
			return client:emit('guildCreate', guild)
		end
	end
end

function EventHandler.GUILD_UPDATE(data, client)
	local guild = client._guilds:get(data.id)
	if not guild then return warning(client, 'guild', 'GUILD_UPDATE') end
	guild:_update(data)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(data, client)
	local guild = client._guilds:get(data.id)
	if not guild then return warning(client, 'guild', 'GUILD_DELETE') end
	if data.unavailable then
		guild._unavailable = true
		return client:emit('guildUnavailable', guild)
	else
		client._guilds:remove(guild)
		return client:emit('guildDelete', guild)
	end
end

function EventHandler.GUILD_BAN_ADD(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_BAN_ADD') end
	local user = client._users:get(data.user.id) or client._users:new(data.user)
	return client:emit('userBan', user, guild)
end

function EventHandler.GUILD_BAN_REMOVE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_BAN_REMOVE') end
	local user = client._users:get(data.user.id) or client._users:new(data.user)
	return client:emit('userUnban', user, guild)
end

function EventHandler.GUILD_MEMBER_ADD(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_MEMBER_ADD') end
	local member = guild._members:new(data)
	guild._member_count = guild._member_count + 1
	return client:emit('memberJoin', member)
end

function EventHandler.GUILD_MEMBER_REMOVE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_MEMBER_REMOVE') end
	local member = guild._members:get(data.user.id)
	if not member then return warning(client, 'member', 'GUILD_MEMBER_REMOVE') end
	guild._members:remove(member)
	guild._member_count = guild._member_count - 1
	return client:emit('memberLeave', member)
end

function EventHandler.GUILD_MEMBER_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_MEMBER_UPDATE') end
	local member = guild._members:get(data.user.id)
	if not member then return warning(client, 'member', 'GUILD_MEMBER_UPDATE') end
	member:_update(data)
	return client:emit('memberUpdate', member)
end

function EventHandler.GUILD_MEMBERS_CHUNK(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_MEMBER_CHUNK') end
	guild._members:merge(data.members)
	if client._loading and guild._member_count == guild._members.count then
		client._loading.chunks[guild._id] = nil
		checkReady(client)
	end
end

function EventHandler.GUILD_ROLE_CREATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_ROLE_CREATE') end
	local role = guild._roles:new(data.role)
	return client:emit('roleCreate', role)
end

function EventHandler.GUILD_ROLE_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_ROLE_UPDATE') end
	local role = guild._roles:get(data.role.id)
	if not role then return warning(client, 'role', 'GUILD_ROLE_UPDATE') end
	role:_update(data.role)
	return client:emit('roleUpdate', role)
end

function EventHandler.GUILD_ROLE_DELETE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'GUILD_ROLE_DELETE') end
	local role = guild._roles:get(data.role_id)
	if not role then return warning(client, 'role', 'GUILD_ROLE_DELETE') end
	guild._roles:remove(role)
	return client:emit('roleDelete', role)
end

function EventHandler.GUILD_SYNC(data, client)
	local guild = client._guilds:get(data.id)
	if not guild then return warning(client, 'guild', 'GUILD_SYNC') end
	guild._members:merge(data.members)
	guild:_loadMemberPresences(data.presences)
	guild._large = data.large
	if guild._large and client._options.fetchMembers then
		guild:_requestMembers()
	end
	if client._loading then
		client._loading.syncs[guild._id] = nil
		checkReady(client)
	end
end

function EventHandler.MESSAGE_CREATE(data, client)
	local channel = client:getTextChannel(data.channel_id) -- shortcut required
	if not channel then return warning(client, 'channel', 'MESSAGE_CREATE') end
	local message = channel._messages:new(data)
	return client:emit('messageCreate', message)
end

function EventHandler.MESSAGE_UPDATE(data, client)
	local channel = client:getTextChannel(data.channel_id) -- shortcut required
	if not channel then return warning(client, 'channel', 'MESSAGE_UPDATE') end
	local message = channel._messages:get(data.id)
	if not message then return client:emit('messageUpdateUncached', channel, data.id) end
	message:_update(data)
	return client:emit('messageUpdate', message)
end

function EventHandler.MESSAGE_DELETE(data, client)
	local channel = client:getTextChannel(data.channel_id) -- shortcut required
	if not channel then return warning(client, 'channel', 'MESSAGE_DELETE') end
	local message = channel._messages:get(data.id)
	if not message then return client:emit('messageDeleteUncached', channel, data.id) end
	channel._messages:remove(message)
	return client:emit('messageDelete', message)
end

function EventHandler.MESSAGE_DELETE_BULK(data, client)
	local channel = client:getTextChannel(data.channel_id) -- shortcut required
	if not channel then return warning(client, 'channel', 'MESSAGE_DELETE_BULK') end
	for _, id in ipairs(data.ids) do
		local message = channel._messages:get(id)
		if not message then
			client:emit('messageDeleteUncached', channel, id)
		else
			client:emit('messageDelete', message)
		end
	end
end

function EventHandler.PRESENCE_UPDATE(data, client)
	if not data.guild_id then return end -- friend update
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'PRESENCE_UPDATE') end
	local member = guild:_updateMemberPresence(data)
	if not member then return warning(client, 'member', 'PRESENCE_UPDATE') end
	return client:emit('presenceUpdate', member)
end

function EventHandler.TYPING_START(data, client)
	local channel = client:getTextChannel(data.channel_id) -- shortcut required
	if not channel then return warning(client, 'channel', 'TYPING_START') end
	local user = client._users:get(data.user_id)
	if not user then return warning(client, 'user', 'TYPING_START') end
	return client:emit('typingStart', user, channel, data.timestamp)
end

function EventHandler.USER_UPDATE(data, client)
	client:_loadUserData(data)
	client._user:_update(data)
	return client:emit('userUpdate', client._user)
end

function EventHandler.VOICE_STATE_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'guild', 'VOICE_STATE_UPDATE') end
	local member = guild._members:get(data.user_id)
	if not member then return warning(client, 'member', 'VOICE_STATE_UPDATE') end
	local mute = data.mute or data.self_mute
	local deaf = data.deaf or data.self_deaf
	local id = data.session_id
	local state = guild._voice_states[id]
	if state then
		if data.channel_id then
			if data.channel_id == state.channel_id then
				guild._voice_states[id] = data
				client:emit('voiceUpdate', member, mute, deaf)
			else
				local old = guild._voice_channels:get(state.channel_id)
				local new = guild._voice_channels:get(data.channel_id)
				guild._voice_states[id] = data
				client:emit('voiceChannelLeave', member, old)
				client:emit('voiceChannelJoin', member, new)
			end
		else
			guild._voice_states[id] = nil
			local old = guild._voice_channels:get(state.channel_id)
			client:emit('voiceChannelLeave', member, old)
			client:emit('voiceDisconnect', member, mute, deaf)
		end
	else
		guild._voice_states[id] = data
		local new = guild._voice_channels:get(data.channel_id)
		client:emit('voiceConnect', member, mute, deaf)
		client:emit('voiceChannelJoin', member, new)
	end
end

return EventHandler
