local EventHandler = setmetatable({}, {__index = function(self, k)
	self[k] = function(_, _, shard)
		return shard:log('warning', 'Unhandled gateway event: %s', k)
	end
	return self[k]
end})

function EventHandler.READY(d, _, shard)
	shard:readySession(d.session_id)
	return _:emit('ready')
end

function EventHandler.RESUMED(_, _, shard)
	shard:resumeSession()
end

function EventHandler.CHANNEL_CREATE() -- GUILDS / DIRECT_MESSAGES
end

function EventHandler.CHANNEL_UPDATE() -- GUILDS / DIRECT_MESSAGES
end

function EventHandler.CHANNEL_DELETE() -- GUILDS / DIRECT_MESSAGES
end

function EventHandler.CHANNEL_PINS_UPDATE() -- GUILDS / DIRECT_MESSAGES
end

function EventHandler.GUILD_CREATE() -- GUILDS
end

function EventHandler.GUILD_UPDATE() -- GUILDS
end

function EventHandler.GUILD_DELETE() -- GUILDS
end

function EventHandler.GUILD_BAN_ADD() -- GUILD_BANS
end

function EventHandler.GUILD_BAN_REMOVE() -- GUILD_BANS
end

function EventHandler.GUILD_EMOJIS_UPDATE() -- GUILD_EMOJIS
end

function EventHandler.GUILD_INTEGRATIONS_UPDATE() -- GUILD_INTEGRATIONS
end

function EventHandler.GUILD_MEMBER_ADD() -- GUILD_MEMBERS
end

function EventHandler.GUILD_MEMBER_UPDATE() -- GUILD_MEMBERS
end

function EventHandler.GUILD_MEMBER_REMOVE() -- GUILD_MEMBERS
end

function EventHandler.GUILD_MEMBERS_CHUNK() -- NOTE: no intent; command response
end

function EventHandler.GUILD_ROLE_CREATE() -- GUILDS
end

function EventHandler.GUILD_ROLE_UDPATE() -- GUILDS
end

function EventHandler.GUILD_ROLE_DELETE() -- GUILDS
end

function EventHandler.INVITE_CREATE() -- GUILD_INVITES
end

function EventHandler.INVITE_DELETE() -- GUILD_INVITES
end

function EventHandler.MESSAGE_CREATE() -- GUILD_MESSAGES / DIRECT_MESSAGES
end

function EventHandler.MESSAGE_UPDATE() -- GUILD_MESSAGES / DIRECT_MESSAGES
end

function EventHandler.MESSAGE_DELETE() -- GUILD_MESSAGES / DIRECT_MESSAGES
end

function EventHandler.MESSAGE_DELETE_BULK() -- GUILD_MESSAGES
end

function EventHandler.MESSAGE_REACTION_ADD() -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
end

function EventHandler.MESSAGE_REACTION_REMOVE() -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
end

function EventHandler.MESSAGE_REACTION_REMOVE_ALL() -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
end

function EventHandler.MESSAGE_REACTION_REMOVE_EMOJI() -- GUILD_MESSAGE_REACTIONS / DIRECT_MESSAGE_REACTIONS
end

function EventHandler.PRESENCE_UPDATE() -- GUILD_PRESENCES
end

function EventHandler.TYPING_START() -- GUILD_MESSAGE_TYPING / DIRECT_MESSAGE_TYPING
end

function EventHandler.USER_UPDATE() -- NOTE: no intent; always received
end

function EventHandler.VOICE_STATE_UPDATE() -- GUILD_VOICE_STATES
end

function EventHandler.VOICE_SERVER_UPDATE() -- NOTE: no intent; command response
end

function EventHandler.WEBHOOKS_UPDATE() -- GUILD_WEBHOOKS
end

return EventHandler
