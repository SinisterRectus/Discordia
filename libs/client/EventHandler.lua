local EventHandler = setmetatable({}, {__index = function(self, k)
	self[k] = function(_, _, shard)
		return shard:log('warning', 'Unhandled gateway event: %s', k)
	end
	return self[k]
end})

function EventHandler.READY(d, client, shard)
	client.state:newUser(d.user)
	shard:readySession(d)
	return shard:checkReady()
end

function EventHandler.RESUMED(_, _, shard)
	return shard:resumeSession()
end

function EventHandler.CHANNEL_CREATE(d, client) -- GUILDS
	local channel = client.state:newChannel(d)
	return client:emit('channelCreate', channel)
end

function EventHandler.CHANNEL_UPDATE(d, client) -- GUILDS
	local channel = client.state:newChannel(d)
	return client:emit('channelUpdate', channel)
end

function EventHandler.CHANNEL_DELETE(d, client) -- GUILDS
	local channel = client.state:newChannel(d)
	return client:emit('channelDelete', channel)
end

function EventHandler.CHANNEL_PINS_UPDATE(d, client) -- GUILDS / DIRECT_MESSAGES
	return client:emit('pinsUpdate', {
		guildId = d.guild_id,
		channelId = d.channel_id,
		timestamp = d.last_pin_timestamp,
	})
end

function EventHandler.GUILD_CREATE(d, client, shard) -- GUILDS
	local guild = client.state:newGuild(d)
	if shard:guildIsLoading(d.id) then
		shard:setGuildReady(d.id)
		client:emit('guildAvailable', guild)
		return shard:checkReady()
	else
		return client:emit('guildCreate', guild)
	end
end

function EventHandler.GUILD_UPDATE(d, client) -- GUILDS
	local guild = client.state:newGuild(d)
	return client:emit('guildUpdate', guild)
end

function EventHandler.GUILD_DELETE(d, client) -- GUILDS
	if d.unavailable then
		return client:emit('guildUnavailable', d.id)
	else
		return client:emit('guildDelete', d.id)
	end
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
	client.state:newEmojis(d.guild_id, d.emojis)
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

function EventHandler.GUILD_MEMBERS_CHUNK(d, client) -- no intent; command response
	client.state:newMembers(d.guild_id, d.members)
	if d.presences then
		client.state:newPresences(d.guild_id, d.presences)
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
	return client:emit('inviteCreate', {
		guildId = d.guild_id,
		channelId = d.channel_id,
		code = d.code,
	})
end

function EventHandler.INVITE_DELETE(d, client) -- GUILD_INVITES
	return client:emit('inviteDelete', {
		guildId = d.guild_id,
		channelId = d.channel_id,
		code = d.code,
	})
end

function EventHandler.MESSAGE_CREATE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	local message = client.state:newMessage(d, true)
	local member
	if d.guild_id and d.member then
		d.member.user = d.author
		member = client.state:newMember(d.guild_id, d.member)
	end
	return client:emit('messageCreate', message, member)
end

function EventHandler.MESSAGE_UPDATE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	local member
	if d.guild_id and d.member then
		d.member.user = d.author
		member = client.state:newMember(d.guild_id, d.member)
	end
	return client:emit('messageUpdate', d.channel_id, d.id, member) -- TODO: provide update data
end

function EventHandler.MESSAGE_DELETE(d, client) -- GUILD_MESSAGES / DIRECT_MESSAGES
	return client:emit('messageDelete', d.channel_id, d.id)
end

function EventHandler.MESSAGE_DELETE_BULK(d, client) -- GUILD_MESSAGES
	return client:emit('messageDeleteBulk', d.channel_id, d.ids)
end

function EventHandler.MESSAGE_REACTION_ADD(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	local member = d.guild_id and d.member and client.state:newMember(d.guild_id, d.member)
	return client:emit('reactionAdd', {
		emoji = d.emoji, -- id, name, animated (all can be nil)
		userId = d.user_id,
		guildId = d.guild_id,
		channelId = d.channel_id,
		messageId = d.message_id,
	}, member)
end

function EventHandler.MESSAGE_REACTION_REMOVE(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemove', {
		emoji = d.emoji, -- id, name, animated (all can be nil)
		userId = d.user_id,
		guildId = d.guild_id, -- no member provided
		channelId = d.channel_id,
		messageId = d.message_id,
	})
end

function EventHandler.MESSAGE_REACTION_REMOVE_ALL(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemoveAll', {
		guildId = d.guild_id,
		channelId = d.channel_id,
		messageId = d.message_id,
	})
end

function EventHandler.MESSAGE_REACTION_REMOVE_EMOJI(d, client) -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
	return client:emit('reactionRemoveEmoji', {
		emoji = d.emoji, -- id, name, animated (all can be nil)
		guildId = d.guild_id,
		channelId = d.channel_id,
		messageId = d.message_id,
	})
end

function EventHandler.PRESENCE_UPDATE(d, client) -- GUILD_PRESENCES
	if not d.guild_id then return end
	local presence = client.state:newPresence(d.guild_id, d)
	return client:emit('presenceUpdate', presence)
end

function EventHandler.TYPING_START(d, client) -- GUILD_MESSAGE_TYPING / DIRECT_MESSAGE_TYPING
	local member = d.guild_id and d.member and client.state:newMember(d.guild_id, d.member)
	return client:emit('typingStart', {
		timestamp = d.timestamp,
		userId = d.user_id,
		guildId = d.guild_id,
		channelId = d.channel_id,
		messageId = d.message_id,
	}, member)
end

function EventHandler.USER_UPDATE(d, client) -- no intent; always received
	local user = client.state:newUser(d)
	return client:emit('userUpdate', user)
end

function EventHandler.VOICE_STATE_UPDATE() -- GUILD_VOICE_STATES
	-- TODO: voice
end

function EventHandler.VOICE_SERVER_UPDATE() -- no intent; command response
	-- TODO: voice
end

function EventHandler.WEBHOOKS_UPDATE(d, client) -- GUILD_WEBHOOKS
	return client:emit('webhookUpdate', {
		guildId = d.guild_id,
		channelId = d.channel_id,
	})
end

return EventHandler
