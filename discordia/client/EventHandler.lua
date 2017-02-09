local format = string.format
local insert = table.insert

local function warning(client, object, id, event)
	return client:warning(format('Uncached %s (%s) on %s', object, id, event))
end

local function checkReady(socket)
	local client = socket._client
	for _, v in pairs(socket._loading) do
		if next(v) then return end
	end
	socket._ready = true
	client:emit('shardReady', socket._id)
	for _, other in pairs(client._sockets) do
		if not other._ready then return end
	end
	collectgarbage()
	return client:emit('ready')
end

local EventHandler = {}

function EventHandler.READY(data, client, socket)

	client._stopwatch:restart()

	socket._session_id = data.session_id

	client:_loadUserData(data.user)
	client._user = client._users:new(data.user)

	client._guilds:merge(data.guilds)
	client._private_channels:merge(data.private_channels)

	if client._user._bot then
		for _, guild in ipairs(data.guilds) do
			socket._loading.guilds[guild.id] = true
		end
	else
		local guild_ids = {}
		for _, guild in ipairs(data.guilds) do
			if not guild.unavailable then
				local id = guild.id
				socket._loading.syncs[id] = true
				insert(guild_ids, id)
			end
		end
		socket:syncGuilds(guild_ids)
	end

	return checkReady(socket)

end

function EventHandler.RESUMED(_, client, socket)
	return client:emit('resumed', socket._id) -- maybe change to shardResumed in future
end

function EventHandler.CHANNEL_CREATE(data, client)
	local channel
	if data.is_private then
		channel = client._private_channels:new(data)
	else
		local guild = client._guilds:get(data.guild_id)
		if not guild then return warning(client, 'Guild', data.guild_id, 'CHANNEL_CREATE') end
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
	if not guild then return warning(client, 'Guild', data.guild_id, 'CHANNEL_UPDATE') end
	if data.type == 'text' then
		channel = guild._text_channels:get(data.id) or guild._text_channels:new(data)
	elseif data.type == 'voice' then
		channel = guild._voice_channels:get(data.id) or guild._voice_channels:new(data)
	end
	channel:_update(data)
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(data, client)
	local channel
	if data.is_private then
		channel = client._private_channels:get(data.id) or client._private_channels:new(data)
		client._private_channels:remove(channel)
	else
		local guild = client._guilds:get(data.guild_id)
		if not guild then return warning(client, 'Guild', data.guild_id, 'CHANNEL_DELETE') end
		if data.type == 'text' then
			channel = guild._text_channels:get(data.id) or guild._text_channels:new(data)
			guild._text_channels:remove(channel)
		elseif data.type == 'voice' then
			channel = guild._voice_channels:get(data.id) or guild._voice_channels:new(data)
			guild._voice_channels:remove(channel)
		end
	end
	return client:emit('channelDelete', channel)
end

function EventHandler.GUILD_CREATE(data, client, socket)
	local id = data.id
	if not data.unavailable and not client._user._bot then
		if socket._loading then
			socket._loading.syncs[id] = true
		end
		socket:syncGuilds({id})
	end
	local guild = client._guilds:get(id)
	if guild then
		if guild._unavailable and not data.unavailable then
			guild:_makeAvailable(data)
			client:emit('guildAvailable', guild)
		else
			client:warning('Erroneous guild availability on GUILD_CREATE')
		end
		if socket._loading then
			socket._loading.guilds[guild._id] = nil
			checkReady(socket)
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
	local guild = client._guilds:get(data.id) or client._guilds:new(data)
	guild:_update(data)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(data, client)
	local guild = client._guilds:get(data.id) or client._guilds:new(data)
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
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_BAN_ADD') end
	local user = client._users:get(data.user.id) or client._users:new(data.user)
	return client:emit('userBan', user, guild)
end

function EventHandler.GUILD_BAN_REMOVE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_BAN_REMOVE') end
	local user = client._users:get(data.user.id) or client._users:new(data.user)
	return client:emit('userUnban', user, guild)
end

function EventHandler.GUILD_EMOJIS_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_EMOJIS_UPDATE') end
	guild._emojis:_update(data.emojis)
	return client:emit('emojisUpdate', guild)
end

function EventHandler.GUILD_MEMBER_ADD(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_MEMBER_ADD') end
	local member = guild._members:new(data)
	guild._member_count = guild._member_count + 1
	return client:emit('memberJoin', member)
end

function EventHandler.GUILD_MEMBER_REMOVE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_MEMBER_REMOVE') end
	local member = guild._members:get(data.user.id) or guild._members:new(data)
	guild._members:remove(member)
	guild._member_count = guild._member_count - 1
	return client:emit('memberLeave', member)
end

function EventHandler.GUILD_MEMBER_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_MEMBER_UPDATE') end
	local member = guild._members:get(data.user.id) or guild._members:new(data)
	member:_update(data)
	return client:emit('memberUpdate', member)
end

function EventHandler.GUILD_MEMBERS_CHUNK(data, client, socket)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_MEMBER_CHUNK') end
	guild._members:merge(data.members)
	if socket._loading and guild._member_count == guild._members.count then
		socket._loading.chunks[guild._id] = nil
		checkReady(socket)
	end
end

function EventHandler.GUILD_ROLE_CREATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_ROLE_CREATE') end
	local role = guild._roles:new(data.role)
	return client:emit('roleCreate', role)
end

function EventHandler.GUILD_ROLE_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_ROLE_UPDATE') end
	local role = guild._roles:get(data.role.id) or guild._roles:new(data.role)
	role:_update(data.role)
	return client:emit('roleUpdate', role)
end

function EventHandler.GUILD_ROLE_DELETE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_ROLE_DELETE') end
	local role = guild._roles:get(data.role_id)
	if not role then return warning(client, 'Role', data.role_id, 'GUILD_ROLE_DELETE') end
	guild._roles:remove(role)
	return client:emit('roleDelete', role)
end

function EventHandler.GUILD_SYNC(data, client, socket)
	local guild = client._guilds:get(data.id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'GUILD_SYNC') end
	guild._members:merge(data.members)
	guild:_loadMemberPresences(data.presences)
	guild._large = data.large
	if guild._large and client._options.fetchMembers then
		guild:_requestMembers()
	end
	if socket._loading then
		socket._loading.syncs[guild._id] = nil
		checkReady(socket)
	end
end

function EventHandler.MESSAGE_CREATE(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_CREATE') end
	local message = channel._messages:new(data)
	return client:emit('messageCreate', message)
end

function EventHandler.MESSAGE_UPDATE(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_UPDATE') end
	local message = channel._messages:get(data.id)
	if not message then return client:emit('messageUpdateUncached', channel, data.id) end
	if message._content ~= data.content then
		message._old_content = message._content
	end
	message:_update(data)
	return client:emit('messageUpdate', message)
end

function EventHandler.MESSAGE_DELETE(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_DELETE') end
	local message = channel._messages:get(data.id)
	if not message then return client:emit('messageDeleteUncached', channel, data.id) end
	channel._messages:remove(message)
	return client:emit('messageDelete', message)
end

function EventHandler.MESSAGE_DELETE_BULK(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_DELETE_BULK') end
	for _, id in ipairs(data.ids) do
		local message = channel._messages:get(id)
		if not message then
			client:emit('messageDeleteUncached', channel, id)
		else
			client:emit('messageDelete', message)
		end
	end
end

function EventHandler.MESSAGE_REACTION_ADD(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_REACTION_ADD') end
	local message = channel._messages:get(data.message_id)
	if message then
		local user = client._users:get(data.user_id)
		if not user then return warning(client, 'User', data.user_id, 'MESSAGE_REACTION_ADD') end
		local reaction = message:_addReaction(data, user)
		return client:emit('reactionAdd', reaction, user)
	else
		return client:emit('reactionAddUncached', data)
	end
end

function EventHandler.MESSAGE_REACTION_REMOVE(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'MESSAGE_REACTION_REMOVE') end
	local message = channel._messages:get(data.message_id)
	if message then
		local user = client._users:get(data.user_id)
		if not user then return warning(client, 'User', data.user_id, 'MESSAGE_REACTION_REMOVE') end
		local reaction = message:_removeReaction(data, user)
		return client:emit('reactionRemove', reaction, user)
	else
		return client:emit('reactionRemoveUncached', data)
	end
end

function EventHandler.PRESENCE_UPDATE(data, client)
	if not data.guild_id then return end -- friend update
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'PRESENCE_UPDATE') end
	local member = guild:_updateMemberPresence(data)
	return client:emit('presenceUpdate', member)
end

function EventHandler.TYPING_START(data, client)
	local channel = client:_getTextChannelShortcut(data.channel_id)
	if not channel then return warning(client, 'TextChannel', data.channel_id, 'TYPING_START') end
	local user = client._users:get(data.user_id)
	if not user then return warning(client, 'User', data.user_id, 'TYPING_START') end
	return client:emit('typingStart', user, channel, data.timestamp)
end

function EventHandler.USER_UPDATE(data, client)
	client:_loadUserData(data)
	client._user:_update(data)
	return client:emit('userUpdate', client._user)
end

function EventHandler.VOICE_STATE_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'VOICE_STATE_UPDATE') end
	local id = data.user_id
	local member = guild._members:get(id)
	if not member then return warning(client, 'Member', id, 'VOICE_STATE_UPDATE') end
	local mute = data.mute or data.self_mute
	local deaf = data.deaf or data.self_deaf
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
				if id == client._user._id then
					client._voice:_resumeJoin(data.guild_id)
				end
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

function EventHandler.VOICE_SERVER_UPDATE(data, client)
	local guild = client._guilds:get(data.guild_id)
	if not guild then return warning(client, 'Guild', data.guild_id, 'VOICE_SERVER_UPDATE') end
	local state = guild._voice_states[client._user._id]
	local channel = guild._voice_channels:get(state.channel_id)
	if not channel then return warning(client, 'GuildVoiceChannel', state.guild_id, 'VOICE_SERVER_UPDATE') end
	return client._voice:_createVoiceConnection(data, channel, state)
end

return EventHandler
