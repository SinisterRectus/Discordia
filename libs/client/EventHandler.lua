local EventHandler = setmetatable({}, {__index = function(self, k)
	self[k] = function(_, _, shard)
		return shard:log('warning', 'Unhandled gateway event: %s', k)
	end
	return self[k]
end})

function EventHandler.READY(d, client, shard)
	client.state:newUser(d.user)
	shard:setLoading(d.guilds)
	shard:readySession(d.session_id)
	return shard:checkReady()
end

function EventHandler.RESUMED(_, _, shard)
	return shard:resumeSession()
end

function EventHandler.CHANNEL_CREATE(d, client) -- GUILDS / DIRECT_MESSAGES
	local channel = client.state:newChannel(d)
	return client:emit('channelCreate', channel)
end

function EventHandler.CHANNEL_UPDATE(d, client) -- GUILDS / DIRECT_MESSAGES
	local channel = client.state:newChannel(d)
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(d, client) -- GUILDS / DIRECT_MESSAGES
	local channel = client.state:newChannel(d)
	return client:emit('channelDelete', channel)
end

function EventHandler.CHANNEL_PINS_UPDATE(d, client) -- GUILDS / DIRECT_MESSAGES
	return client:emit('pinsUpdate', d.channel_id, d.last_pin_timestamp)
end

function EventHandler.GUILD_CREATE(d, client, shard) -- GUILDS
	local guild = client.state:newGuild(d)
	client:emit('guildCreate', guild)
	shard:setGuildReady(d.id)
	return shard:checkReady()
end

function EventHandler.GUILD_UPDATE(d, client) -- GUILDS
	local guild = client.state:newGuild(d)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(d, client) -- GUILDS
	return client:emit('guildDelete', d.id)
end

function EventHandler.GUILD_BAN_ADD(d, client) -- GUILD_BANS
	local user = client.state:newUser(d.user)
	return client:emit('userBan', d.guild_id, user)
end

function EventHandler.GUILD_BAN_REMOVE(d, client) -- GUILD_BANS
	local user = client.state:newUser(d.user)
	return client:emit('userUnban', d.guild_id, user)
end

function EventHandler.GUILD_EMOJIS_UPDATE(d, client) -- GUILD_EMOJIS
	for _, v in ipairs(d.emojis) do
		client.state:newEmoji(d.guild_id, v)
	end
	return client:emit('emojisUpdate', d.guild_id)
end

function EventHandler.GUILD_INTEGRATIONS_UPDATE(d, client) -- GUILD_INTEGRATIONS
	return client:emit('integrationsUpdate', d.guild_id)
end

function EventHandler.GUILD_MEMBER_ADD(d, client) -- GUILD_MEMBERS
	local member = client.state:newMember(d.guild_id, d)
	return client:emit('memberJoin', member)
end

function EventHandler.GUILD_MEMBER_UPDATE(d, client) -- GUILD_MEMBERS
	local member = client.state:newMember(d.guild_id, d)
	return client:emit('memberUpdate', member)
end

function EventHandler.GUILD_MEMBER_REMOVE(d, client) -- GUILD_MEMBERS
	local user = client.state:newUser(d.user)
	return client:emit('memberRemove', d.guild_id, user)
end

function EventHandler.GUILD_MEMBERS_CHUNK(d, client) -- NOTE: no intent; command response
	for _, v in ipairs(d.members) do
		client.state:newMember(d.guild_id, v)
	end
	return client:emit('membersChunk', d.guild_id)
end

function EventHandler.GUILD_ROLE_CREATE(d, client) -- GUILDS
	local role = client.state:newRole(d.guild_id, d.role)
	return client:emit('roleCreate', role)
end

function EventHandler.GUILD_ROLE_UPDATE(d, client) -- GUILDS
	local role = client.state:newRole(d.guild_id, d.role)
	return client:emit('roleUpdate', role)
end

function EventHandler.GUILD_ROLE_DELETE(d, client) -- GUILDS
	return client:emit('roleDelete', d.guild_id, d.role_id)
end

function EventHandler.INVITE_CREATE(d, client) -- GUILD_INVITES
	return client:emit('inviteCreate', d.channel_id, d.code)
end

function EventHandler.INVITE_DELETE(d, client) -- GUILD_INVITES
	return client:emit('inviteDelete', d.channel_id, d.code)
end

function EventHandler.MESSAGE_CREATE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	local message = client.state:newMessage(d.channel_id, d, true)
	return client:emit('messageCreate', message)
end

function EventHandler.MESSAGE_UPDATE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	client.state:updateMessage(d)
	return client:emit('messageUpdate', d.channel_id, d.id)
end

function EventHandler.MESSAGE_DELETE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	return client:emit('messageDelete', d.channel_id, d.id)
end

function EventHandler.MESSAGE_DELETE_BULK(d, client) -- GUILD_MESSAGES
	return client:emit('messageDeleteBulk', d.channel_id, d.ids)
end

function EventHandler.MESSAGE_REACTION_ADD(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	if d.guild_id and d.member then
		client.state:newMember(d.guild_id, d.member)
	end
	return client:emit('reactionAdd', d.channel_id, d.message_id, d.user_id, d.emoji)
end

function EventHandler.MESSAGE_REACTION_REMOVE(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemove', d.channel_id, d.message_id, d.user_id, d.emoji)
end

function EventHandler.MESSAGE_REACTION_REMOVE_ALL(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemoveAll', d.channel_id, d.message_id)
end

function EventHandler.MESSAGE_REACTION_REMOVE_EMOJI(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemoveEmoji', d.channel_id, d.message_id, d.emoji)
end

function EventHandler.PRESENCE_UPDATE() -- GUILD_PRESENCES
	-- TODO
end

function EventHandler.TYPING_START(d, client) -- GUILD_MESSAGE_TYPING / DIRECT_MESSAGE_TYPING
	if d.guild_id and d.member then
		client.state:newMember(d.guild_id, d.member)
	end
	return client:emit('typingStart', d.channel_id, d.user_id, d.timestamp)
end

function EventHandler.USER_UPDATE(d, client) -- NOTE: no intent; always received
	local user = client.state:newUser(d)
	return client:emit('userUpdate', user)
end

function EventHandler.VOICE_STATE_UPDATE() -- GUILD_VOICE_STATES
	-- TODO
end

function EventHandler.VOICE_SERVER_UPDATE() -- NOTE: no intent; command response
	-- TODO
end

function EventHandler.WEBHOOKS_UPDATE(d, client) -- GUILD_WEBHOOKS
	return client:emit('webhookUpdate', d.guild_id, d.channel_id)
end

return EventHandler
