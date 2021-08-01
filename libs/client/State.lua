local Application = require('../containers/Application')
local Command = require('../containers/Command')
local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local GuildEmoji = require('../containers/GuildEmoji')
local Guild = require('../containers/Guild')
local GuildPreview = require('../containers/GuildPreview')
local GuildTemplate = require('../containers/GuildTemplate')
local Interaction = require('../containers/Interaction')
local Invite = require('../containers/Invite')
local GuildMember = require('../containers/GuildMember')
local Message = require('../containers/Message')
local MessageInteraction = require('../containers/MessageInteraction')
local PermissionOverwrite = require('../containers/PermissionOverwrite')
local Presence = require('../containers/Presence')
local Reaction = require('../containers/Reaction')
local GuildRole = require('../containers/GuildRole')
local StageInstance = require('../containers/StageInstance')
local Team = require('../containers/Team')
local TeamMember = require('../containers/TeamMember')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')
local WelcomeScreen = require('../containers/WelcomeScreen')

local Iterable = require('../utils/Iterable')
local Cache = require('./Cache')
local CompoundCache = require('./CompoundCache')

local class = require('../class')

local State = class('State')

local channelMap = {} -- channelId -> guildId

function State:__init(client)

	self._client = assert(client)

	self._privateMap = {} -- userId -> channelId
	self._applicationId = nil

	self._users = Cache(User, client, true)
	self._commands = Cache(Command, client, true)
	self._stages = Cache(StageInstance, client, true)

	self._guilds = Cache(Guild, client)
	self._roles = CompoundCache(GuildRole, client)
	self._emojis = CompoundCache(GuildEmoji, client)
	self._channels = CompoundCache(Channel, client)

	self._reactions = CompoundCache(Reaction, client, true)
	self._overwrites = CompoundCache(PermissionOverwrite, client, true)

end

function State:getDMChannelId(userId)
	if self._privateMap[userId] == nil then
		local channel, err = self._client.api:createDM {recipient_id = userId}
		if channel then
			self._privateMap[userId] = channel.id
		else
			return nil, err
		end
	end
	return self._privateMap[userId]
end

function State:newUser(data)
	return self._users:update(data.id, data)
end

function State:newUsers(data)
	for i, v in ipairs(data) do
		data[i] = self:newUser(v)
	end
	return Iterable(data, 'id')
end

function State:newGuild(data)
	return self._guilds:update(data.id, data)
end

function State:newGuilds(data)
	for i, v in ipairs(data) do
		data[i] = self:newGuild(v)
	end
	return Iterable(data, 'id')
end

function State:newGuildPreview(data)
	return GuildPreview(data, self._client)
end

function State:newInvite(data)
	return Invite(data, self._client)
end

function State:newInvites(data)
	for i, v in ipairs(data) do
		data[i] = self:newInvite(v)
	end
	return Iterable(data, 'code')
end

function State:newGuildTemplate(data)
	return GuildTemplate(data, self._client)
end

function State:newGuildTemplates(data)
	for i, v in ipairs(data) do
		data[i] = self:newGuildTemplate(v)
	end
	return Iterable(data, 'code')
end

function State:newWelcomeScreen(guildId, data)
	data.guild_id = guildId
	return WelcomeScreen(data, self._client)
end

function State:newWebhook(data)
	return Webhook(data, self._client)
end

function State:newWebhooks(data)
	for i, v in ipairs(data) do
		data[i] = self:newWebhook(v)
	end
	return Iterable(data, 'id')
end

function State:newStageInstance(data)
	return self._stages:update(data.id, data)
end

function State:newTeam(data)
	return Team(data, self._client)
end

function State:newTeamMember(data)
	return TeamMember(data, self._client)
end

function State:newTeamMembers(data)
	for i, v in ipairs(data) do
		data[i] = self:newTeamMember(v)
	end
	return Iterable(data, 'id')
end

function State:newApplication(data)
	return Application(data, self._client)
end

function State:newCommand(data)
	return self._commands:update(data.id, data)
end

function State:newCommands(data)
	for i, v in ipairs(data) do
		data[i] = self:newCommand(v)
	end
	return Iterable(data, 'id')
end

function State:newInteraction(data)
	return Interaction(data, self._client)
end

function State:newMessageInteraction(data)
	return MessageInteraction(data, self._client)
end

function State:newGuildRole(guildId, data)
	data.guild_id = guildId
	return self._roles:update(guildId, data.id, data)
end

function State:newGuildRoles(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newGuildRole(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newGuildEmoji(guildId, data)
	data.guild_id = guildId
	return self._emojis:update(guildId, data.id, data)
end

function State:newGuildEmojis(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newGuildEmoji(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newGuildMember(guildId, data)
	data.guild_id = guildId
	return GuildMember(data, self._client)
end

function State:newGuildMembers(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newGuildMember(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newBan(guildId, data)
	data.guild_id = guildId
	return Ban(data, self._client)
end

function State:newBans(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newBan(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newAuditLogEntry(guildId, data)
	data.guild_id = guildId
	return AuditLogEntry(data, self._client)
end

function State:newAuditLogEntries(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newAuditLogEntry(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newPresence(guildId, data)
	data.guild_id = guildId
	return Presence(data, self._client)
end

function State:newPresences(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newPresence(guildId, v)
	end
	return Iterable(data, 'userId')
end

function State:newChannel(data)
	if data.guild_id then
		channelMap[data.id] = data.guild_id
		return self._channels:update(data.guild_id, data.id, data)
	else
		channelMap[data.id] = '@me'
		return Channel(data, self._client)
	end
end

function State:newChannels(data)
	for i, v in ipairs(data) do
		data[i] = self:newChannel(v)
	end
	return Iterable(data, 'id')
end

function State:newMessage(data, gateway)
	local channelId = data.channel_id
	if gateway then
		channelMap[channelId] = channelMap[channelId] or data.guild_id or '@me'
	else
		local guildId = channelMap[channelId]
		if guildId ~= '@me' then
			data.guild_id = guildId
		end
	end
	return Message(data, self._client)
end

function State:newMessages(data, gateway)
	for i, v in ipairs(data) do
		data[i] = self:newMessage(v, gateway)
	end
	return Iterable(data, 'id')
end

----

function State:newReaction(channelId, messageId, data)
	data.channel_id = channelId
	data.message_id = messageId
	local emoji = data.emoji
	return self._reactions:update(messageId, emoji.id or emoji.name, data)
end

function State:newReactions(channelId, messageId, data)
	for i, v in ipairs(data) do
		data[i] = self:newReaction(channelId, messageId, v)
	end
	return Iterable(data, 'hash')
end

function State:newPermissionOverwrite(channelId, data)
	data.channel_id = channelId
	return self._overwrites:update(channelId, data.id, data)
end

function State:newPermissionOverwrites(channelId, data)
	for i, v in ipairs(data) do
		data[i] = self:newPermissionOverwrite(channelId, v)
	end
	return Iterable(data, 'id')
end

----

function State:getGuild(guildId)
	return self._guilds:get(guildId)
end

function State:getChannel(channelId)
	local guildId = channelMap[channelId]
	return self._channels:get(guildId, channelId)
end

function State:getGuildChannel(guildId, channelId)
	return self._channels:get(guildId, channelId)
end

function State:getGuildRole(guildId, roleId)
	return self._roles:get(guildId, roleId)
end

function State:getGuildEmoji(guildId, emojiId)
	return self._emojis:get(guildId, emojiId)
end

function State:getGuilds()
	return Iterable(self._guilds:toArray(), 'id')
end

function State:getGuildChannels(guildId)
	return Iterable(self._channels:toArray(guildId), 'id')
end

function State:getGuildRoles(guildId)
	return Iterable(self._roles:toArray(guildId), 'id')
end

function State:getGuildEmojis(guildId)
	return Iterable(self._emojis:toArray(guildId), 'id')
end

----

function State:deleteGuild(guildId)
	self._channels:delete(guildId)
	self._roles:delete(guildId)
	self._emojis:delete(guildId)
	return self._guilds:delete(guildId)
end

function State:deleteChannel(channelId)
	local guildId = channelMap[channelId]
	return self._channels:delete(guildId, channelId)
end

function State:deleteGuildChannel(guildId, channelId)
	return self._channels:delete(guildId, channelId)
end

function State:deleteGuildRole(guildId, roleId)
	return self._roles:delete(guildId, roleId)
end

function State:deleteGuildEmoji(guildId, emojiId)
	return self._emojis:delete(guildId, emojiId)
end

----

function State:deleteGuildChannels(guildId)
	return self._channels:delete(guildId)
end

function State:deleteGuildRoles(guildId)
	return self._roles:delete(guildId)
end

function State:deleteGuildEmojis(guildId)
	return self._emojis:delete(guildId)
end

return State
