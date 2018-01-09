local enums = require('enums')
local json = require('json')

local channelType = enums.channelType
local concat, insert = table.concat, table.insert
local null = json.null

local function warning(client, object, id, event)
	return client:warning('Uncached %s (%s) on %s', object, id, event)
end

local function checkReady(shard)
	for _, v in pairs(shard._loading) do
		if next(v) then return end
	end
	shard._ready = true
	shard._loading = nil
	collectgarbage()
	local client = shard._client
	client:emit('shardReady', shard._id)
	for _, other in pairs(client._shards) do
		if not other._ready then return end
	end
	return client:emit('ready')
end

local function getChannel(client, id)
	local guild = client._channel_map[id]
	if guild then
		return guild._text_channels:get(id)
	else
		return client._private_channels:get(id) or client._group_channels:get(id)
	end
end

local EventHandler = setmetatable({}, {__index = function(self, k)
	self[k] = function(_, _, shard)
		return shard:warning('Unhandled gateway event: %s', k)
	end
	return self[k]
end})

function EventHandler.READY(d, client, shard)

	shard:info('Received READY (%s)', concat(d._trace, ', '))
	shard:emit('READY')

	shard._session_id = d.session_id
	client._user = client._users:_insert(d.user)

	local guilds = client._guilds
	local group_channels = client._group_channels
	local private_channels = client._private_channels
	local relationships = client._relationships

	for _, channel in ipairs(d.private_channels) do
		if channel.type == channelType.private then
			private_channels:_insert(channel)
		elseif channel.type == channelType.group then
			group_channels:_insert(channel)
		end
	end

	local loading = shard._loading

	if d.user.bot then
		for _, guild in ipairs(d.guilds) do
			guilds:_insert(guild)
			loading.guilds[guild.id] = true
		end
	else
		if client._options.syncGuilds then
			local ids = {}
			for _, guild in ipairs(d.guilds) do
				guilds:_insert(guild)
				if not guild.unavailable then
					loading.syncs[guild.id] = true
					insert(ids, guild.id)
				end
			end
			shard:syncGuilds(ids)
		else
			guilds:_load(d.guilds)
		end
	end

	relationships:_load(d.relationships)

	for _, presence in ipairs(d.presences) do
		local relationship = relationships:get(presence.user.id)
		if relationship then
			relationship:_loadPresence(presence)
		end
	end

	return checkReady(shard)

end

function EventHandler.RESUMED(d, client, shard)
	shard:info('Received RESUMED (%s)', concat(d._trace, ', '))
	return client:emit('shardResumed', shard._id)
end

function EventHandler.GUILD_MEMBERS_CHUNK(d, client, shard)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_MEMBERS_CHUNK') end
	guild._members:_load(d.members)
	if shard._loading and guild._member_count == #guild._members then
		shard._loading.chunks[d.guild_id] = nil
		return checkReady(shard)
	end
end

function EventHandler.GUILD_SYNC(d, client, shard)
	local guild = client._guilds:get(d.id)
	if not guild then return warning(client, 'Guild', d.id, 'GUILD_SYNC') end
	guild._large = d.large
	guild:_loadMembers(d, shard)
	if shard._loading then
		shard._loading.syncs[d.id] = nil
		return checkReady(shard)
	end
end

function EventHandler.CHANNEL_CREATE(d, client)
	local channel
	local t = d.type
	if t == channelType.text then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_CREATE') end
		channel = guild._text_channels:_insert(d)
	elseif t == channelType.voice then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_CREATE') end
		channel = guild._voice_channels:_insert(d)
	elseif t == channelType.private then
		channel = client._private_channels:_insert(d)
	elseif t == channelType.group then
		channel = client._group_channels:_insert(d)
	elseif t == channelType.category then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_CREATE') end
		channel = guild._categories:_insert(d)
	else
		return client:warning('Unhandled CHANNEL_CREATE (type %s)', d.type)
	end
	return client:emit('channelCreate', channel)
end

function EventHandler.CHANNEL_UPDATE(d, client)
	local channel
	local t = d.type
	if t == channelType.text then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_UPDATE') end
		channel = guild._text_channels:_insert(d)
	elseif t == channelType.voice then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_UPDATE') end
		channel = guild._voice_channels:_insert(d)
	elseif t == channelType.private then -- private channels should never update
		channel = client._private_channels:_insert(d)
	elseif t == channelType.group then
		channel = client._group_channels:_insert(d)
	elseif t == channelType.category then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_UPDATE') end
		channel = guild._categories:_insert(d)
	else
		return client:warning('Unhandled CHANNEL_UPDATE (type %s)', d.type)
	end
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(d, client)
	local channel
	local t = d.type
	if t == channelType.text then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_DELETE') end
		channel = guild._text_channels:_remove(d)
	elseif t == channelType.voice then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_DELETE') end
		channel = guild._voice_channels:_remove(d)
	elseif t == channelType.private then
		channel = client._private_channels:_remove(d)
	elseif t == channelType.group then
		channel = client._group_channels:_remove(d)
	elseif t == channelType.category then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'CHANNEL_DELETE') end
		channel = guild._categories:_remove(d)
	else
		return client:warning('Unhandled CHANNEL_DELETE (type %s)', d.type)
	end
	return client:emit('channelDelete', channel)
end

function EventHandler.CHANNEL_RECIPIENT_ADD(d, client)
	local channel = client._group_channels:get(d.channel_id)
	if not channel then return warning(client, 'GroupChannel', d.channel_id, 'CHANNEL_RECIPIENT_ADD') end
	local user = channel._recipients:_insert(d.user)
	return client:emit('recipientAdd', channel, user)
end

function EventHandler.CHANNEL_RECIPIENT_REMOVE(d, client)
	local channel = client._group_channels:get(d.channel_id)
	if not channel then return warning(client, 'GroupChannel', d.channel_id, 'CHANNEL_RECIPIENT_REMOVE') end
	local user = channel._recipients:_remove(d.user)
	return client:emit('recipientRemove', channel, user)
end

function EventHandler.GUILD_CREATE(d, client, shard)
	if client._options.syncGuilds and not d.unavailable and not client._user._bot then
		shard:syncGuilds({d.id})
	end
	local guild = client._guilds:get(d.id)
	if guild then
		if guild._unavailable and not d.unavailable then
			guild:_load(d)
			guild:_makeAvailable(d)
			client:emit('guildAvailable', guild)
		end
		if shard._loading then
			shard._loading.guilds[d.id] = nil
			return checkReady(shard)
		end
	else
		guild = client._guilds:_insert(d)
		return client:emit('guildCreate', guild)
	end
end

function EventHandler.GUILD_UPDATE(d, client)
	local guild = client._guilds:_insert(d)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(d, client)
	if d.unavailable then
		local guild = client._guilds:_insert(d)
		return client:emit('guildUnavailable', guild)
	else
		local guild = client._guilds:_remove(d)
		return client:emit('guildDelete', guild)
	end
end

function EventHandler.GUILD_BAN_ADD(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_BAN_ADD') end
	local user = client._users:_insert(d.user)
	return client:emit('userBan', user, guild)
end

function EventHandler.GUILD_BAN_REMOVE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_BAN_REMOVE') end
	local user = client._users:_insert(d.user)
	return client:emit('userUnban', user, guild)
end

function EventHandler.GUILD_EMOJIS_UPDATE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_EMOJIS_UPDATE') end
	guild._emojis:_load(d.emojis, true)
	return client:emit('emojisUpdate', guild)
end

function EventHandler.GUILD_MEMBER_ADD(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_MEMBER_ADD') end
	local member = guild._members:_insert(d)
	guild._member_count = guild._member_count + 1
	return client:emit('memberJoin', member)
end

function EventHandler.GUILD_MEMBER_UPDATE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_MEMBER_UPDATE') end
	local member = guild._members:_insert(d)
	return client:emit('memberUpdate', member)
end

function EventHandler.GUILD_MEMBER_REMOVE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_MEMBER_REMOVE') end
	local member = guild._members:_remove(d)
	guild._member_count = guild._member_count - 1
	return client:emit('memberLeave', member)
end

function EventHandler.GUILD_ROLE_CREATE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_ROLE_CREATE') end
	local role = guild._roles:_insert(d.role)
	return client:emit('roleCreate', role)
end

function EventHandler.GUILD_ROLE_UPDATE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_ROLE_UPDATE') end
	local role = guild._roles:_insert(d.role)
	return client:emit('roleUpdate', role)
end

function EventHandler.GUILD_ROLE_DELETE(d, client) -- role object not provided
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'GUILD_ROLE_DELETE') end
	local role = guild._roles:_delete(d.role_id)
	if not role then return warning(client, 'Role', d.role_id, 'GUILD_ROLE_DELETE') end
	return client:emit('roleDelete', role)
end

function EventHandler.MESSAGE_CREATE(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_CREATE') end
	local message = channel._messages:_insert(d)
	return client:emit('messageCreate', message)
end

function EventHandler.MESSAGE_UPDATE(d, client) -- may not contain the whole message
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_UPDATE') end
	local message = channel._messages:get(d.id)
	if message then
		message:_setOldContent(d)
		message:_load(d)
		return client:emit('messageUpdate', message)
	else
		return client:emit('messageUpdateUncached', channel, d.id)
	end
end

function EventHandler.MESSAGE_DELETE(d, client) -- message object not provided
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_DELETE') end
	local message = channel._messages:_delete(d.id)
	if message then
		return client:emit('messageDelete', message)
	else
		return client:emit('messageDeleteUncached', channel, d.id)
	end
end

function EventHandler.MESSAGE_DELETE_BULK(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_DELETE_BULK') end
	for _, id in ipairs(d.ids) do
		local message = channel._messages:_delete(id)
		if message then
			client:emit('messageDelete', message)
		else
			client:emit('messageDeleteUncached', channel, id)
		end
	end
end

function EventHandler.MESSAGE_REACTION_ADD(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_REACTION_ADD') end
	local message = channel._messages:get(d.message_id)
	if message then
		local reaction = message:_addReaction(d)
		return client:emit('reactionAdd', reaction, d.user_id)
	else
		local k = d.emoji.id ~= null and d.emoji.id or d.emoji.name
		return client:emit('reactionAddUncached', channel, d.message_id, k, d.user_id)
	end
end

function EventHandler.MESSAGE_REACTION_REMOVE(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_REACTION_REMOVE') end
	local message = channel._messages:get(d.message_id)
	if message then
		local reaction = message:_removeReaction(d)
		if not reaction then -- uncached reaction?
			local k = d.emoji.id ~= null and d.emoji.id or d.emoji.name
			return warning(client, 'Reaction', k, 'MESSAGE_REACTION_REMOVE')
		end
		return client:emit('reactionRemove', reaction, d.user_id)
	else
		local k = d.emoji.id ~= null and d.emoji.id or d.emoji.name
		return client:emit('reactionRemoveUncached', channel, d.message_id, k, d.user_id)
	end
end

function EventHandler.MESSAGE_REACTION_REMOVE_ALL(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'MESSAGE_REACTION_REMOVE_ALL') end
	local message = channel._messages:get(d.message_id)
	if message then
		local reactions = message._reactions
		if reactions then
			for reaction in reactions:iter() do
				reaction._count = 0
			end
			message._reactions = nil
		end
		return client:emit('reactionRemoveAll', message)
	else
		return client:emit('reactionRemoveAllUncached', channel, d.message_id)
	end
end

function EventHandler.CHANNEL_PINS_UPDATE(d, client)
	local channel = getChannel(client, d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'CHANNEL_PINS_UPDATE') end
	return client:emit('pinsUpdate', channel)
end

function EventHandler.PRESENCE_UPDATE(d, client) -- may have incomplete data
	local user = client._users:get(d.user.id)
	if user then
		user:_load(d.user)
	end
	if d.guild_id then
		local guild = client._guilds:get(d.guild_id)
		if not guild then return warning(client, 'Guild', d.guild_id, 'PRESENCE_UPDATE') end
		local member
		if client._options.cacheAllMembers then
			member = guild._members:get(d.user.id)
			if not member then return end -- still loading or member left
		else
			if d.status == 'offline' and guild._large then
				member = guild._members:_delete(d.user.id)
			else
				if d.user.username then -- member was offline
					member = guild._members:_insert(d)
				elseif user then -- member was invisible, user is still cached
					member = guild._members:_insert(d)
					member._user = user
				end
			end
		end
		if member then
			member:_loadPresence(d)
			return client:emit('presenceUpdate', member)
		end
	else
		local relationship = client._relationships:get(d.user.id)
		if relationship then
			relationship:_loadPresence(d)
			return client:emit('relationshipUpdate', relationship)
		end
	end
end

function EventHandler.RELATIONSHIP_ADD(d, client)
	local relationship = client._relationships:_insert(d)
	return client:emit('relationshipAdd', relationship)
end

function EventHandler.RELATIONSHIP_REMOVE(d, client)
	local relationship = client._relationships:_remove(d)
	return client:emit('relationshipRemove', relationship)
end

function EventHandler.TYPING_START(d, client)
	return client:emit('typingStart', d.user_id, d.channel_id, d.timestamp)
end

function EventHandler.USER_UPDATE(d, client)
	client._user:_load(d)
	return client:emit('userUpdate', client._user)
end

function EventHandler.VOICE_STATE_UPDATE(d, client)
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'VOICE_STATE_UPDATE') end
	local member = guild._members:get(d.user_id)
	if not member then return warning(client, 'Member', d.user_id, 'VOICE_STATE_UPDATE') end
	local states = guild._voice_states
	local channels = guild._voice_channels
	local state = states[d.user_id]
	if state then
		if d.channel_id ~= null then
			states[d.user_id] = d
			if d.channel_id == state.channel_id then
				client:emit('voiceUpdate', member)
			else
				local old = channels:get(state.channel_id)
				local new = channels:get(d.channel_id)
				client:emit('voiceChannelLeave', member, old)
				client:emit('voiceChannelJoin', member, new)
			end
		else
			states[d.user_id] = nil
			local old = channels:get(state.channel_id)
			client:emit('voiceChannelLeave', member, old)
			client:emit('voiceDisconnect', member)
		end
	else
		states[d.user_id] = d
		local new = channels:get(d.channel_id)
		client:emit('voiceConnect', member)
		client:emit('voiceChannelJoin', member, new)
	end
end

function EventHandler.VOICE_SERVER_UPDATE() -- TODO
end

function EventHandler.WEBHOOKS_UPDATE(d, client) -- webhook object is not provided
	local guild = client._guilds:get(d.guild_id)
	if not guild then return warning(client, 'Guild', d.guild_id, 'WEBHOOKS_UDPATE') end
	local channel = guild._text_channels:get(d.channel_id)
	if not channel then return warning(client, 'TextChannel', d.channel_id, 'WEBHOOKS_UPDATE') end
	return client:emit('webhooksUpdate', channel)
end

return EventHandler
