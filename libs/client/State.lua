local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local Emoji = require('../containers/Emoji')
local Guild = require('../containers/Guild')
local Invite = require('../containers/Invite')
local Member = require('../containers/Member')
local Message = require('../containers/Message')
local PermissionOverwrite = require('../containers/PermissionOverwrite')
local Presence = require('../containers/Presence')
local Reaction = require('../containers/Reaction')
local Role = require('../containers/Role')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')

local Cache = require('./Cache')
local CompoundCache = require('./CompoundCache')
local Bitfield = require('../utils/Bitfield')

local class = require('../class')
local enums = require('../enums')

local State = class('State')

local channelMap = {} -- channelId -> guildId

function State:__init(client)

	self._client = assert(client)

	-- TODO: caching rules
	-- TODO: reactions

	self._users = Cache(User, client)
	self._guilds = Cache(Guild, client)
	self._invites = Cache(Invite, client)
	self._webhooks = Cache(Webhook, client)
	self._privates = Cache(Channel, client)

	self._roles = CompoundCache(Role, client)
	self._emojis = CompoundCache(Emoji, client)
	self._members = CompoundCache(Member, client)
	self._bans = CompoundCache(Ban, client)
	self._entries = CompoundCache(AuditLogEntry, client)
	self._presences = CompoundCache(Presence, client)
	self._channels = CompoundCache(Channel, client)
	self._messages = CompoundCache(Message, client)
	self._overwrites = CompoundCache(PermissionOverwrite, client)
	self._reactions = CompoundCache(Reaction, client)

end

function State:getGuildId(channelId)
	if channelMap[channelId] == nil then
		local channel, err = self._client.api:getChannel(channelId)
		if channel then
			channelMap[channelId] = channel.guild_id or '@me'
		else
			return nil, err
		end
	end
	return channelMap[channelId]
end

function State:newUser(data)
	if self._users then
		return self._users:update(data.id, data)
	else
		return User(data, self._client)
	end
end

function State:newUsers(data)
	for i, v in ipairs(data) do
		data[i] = self:newUser(v)
	end
	return data
end

function State:newGuild(data)
	if self._guilds then
		return self._guilds:update(data.id, data)
	else
		return Guild(data, self._client)
	end
end

function State:newGuilds(data)
	for i, v in ipairs(data) do
		data[i] = self:newGuild(v)
	end
	return data
end

function State:newInvite(data)
	if self._invites then
		return self._invites:update(data.code, data)
	else
		return Invite(data, self._client)
	end
end

function State:newInvites(data)
	for i, v in ipairs(data) do
		data[i] = self:newInvite(v)
	end
	return data
end

function State:newWebhook(data)
	if self._webhooks then
		return self._webhooks:update(data.id, data)
	else
		return Webhook(data, self._client)
	end
end

function State:newWebhooks(data)
	for i, v in ipairs(data) do
		data[i] = self:newWebhook(v)
	end
	return data
end

function State:newRole(guildId, data)
	data.guild_id = guildId
	if self._roles then
		return self._roles:update(guildId, data.id, data)
	else
		return Role(data, self._client)
	end
end

function State:newRoles(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newRole(guildId, v)
	end
	return data
end

function State:newEmoji(guildId, data)
	data.guild_id = guildId
	if self._emojis then
		return self._emojis:update(guildId, data.id, data)
	else
		return Emoji(data, self._client)
	end
end

function State:newEmojis(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newEmoji(guildId, v)
	end
	return data
end

function State:newMember(guildId, data)
	data.guild_id = guildId
	if self._members then
		return self._members:update(guildId, data.user.id, data)
	else
		return Member(data, self._client)
	end
end

function State:newMembers(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newMember(guildId, v)
	end
	return data
end

function State:newBan(guildId, data)
	data.guild_id = guildId
	if self._bans then
		return self._bans:update(guildId, data.user.id, data)
	else
		return Ban(data, self._client)
	end
end

function State:newBans(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newBan(guildId, v)
	end
	return data
end

function State:newAuditLogEntry(guildId, data)
	data.guild_id = guildId
	if self._entries then
		return self._entries:update(guildId, data.id, data)
	else
		return AuditLogEntry(data, self._client)
	end
end

function State:newAuditLogEntries(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newAuditLogEntry(guildId, v)
	end
	return data
end

function State:newPresence(guildId, data)
	data.guild_id = guildId
	if self._presences then
		return self._presences:update(guildId, data.user.id, data)
	else
		return Presence(data, self._client)
	end
end

function State:newPresences(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newPresence(guildId, v)
	end
	return data
end

function State:newChannel(data)
	if data.guild_id then
		channelMap[data.id] = data.guild_id
		if self._privates then
			return self._privates:update(data.id, data)
		else
			return Channel(data, self._client)
		end
	else
		if self._channels then
			return self._channels:update(data.guild_id, data.id, data)
		else
			return Channel(data, self._client)
		end
	end
end

function State:newChannels(data)
	for i, v in ipairs(data) do
		data[i] = self:newChannel(v)
	end
	return data
end

function State:newMessage(data, gateway)
	local channelId = data.channel_id
	if gateway then
		channelMap[channelId] = channelMap[channelId] or data.guild_id or '@me'
	else
		local guildId = self:getGuildId(channelId)
		if guildId ~= '@me' then
			data.guild_id = guildId
		end
	end
	if self._messages then
		return self._messages:update(channelId, data.id, data)
	else
		return Message(data, self._client)
	end
end

function State:newMessages(data, gateway)
	for i, v in ipairs(data) do
		data[i] = self:newMessage(v, gateway)
	end
	return data
end

function State:newOverwrite(channelId, data)
	data.channel_id = channelId
	if self._overwrites then
		self._overwrites:update(channelId, data.id, data)
	else
		return PermissionOverwrite(data, self._client)
	end
end

function State:newOverwrites(channelId, data)
	for i, v in ipairs(data) do
		data[i] = self:newOverwrite(channelId, v)
	end
	return data
end

----

function State:getGuild(guildId)
	return self._guilds and self._guilds:get(guildId)
end

function State:getInvite(code)
	return self._invites and self._invites:get(code)
end

function State:getWebhook(webhookId)
	return self._webhooks and self._webhooks:get(webhookId)
end

function State:getRole(guildId, roleId)
	return self._roles and self._roles:get(guildId, roleId)
end

function State:getEmoji(guildId, emojiId)
	return self._emojis and self._emojis:get(guildId, emojiId)
end

function State:getMember(guildId, userId)
	return self._members and self._members:get(guildId, userId)
end

function State:getBan(guildId, userId)
	return self._bans and self._bans:get(guildId, userId)
end

function State:getPresence(guildId, userId)
	return self._presences and self._presences:get(guildId, userId)
end

function State:getChannel(channelId)
	local guildId = channelMap[channelId]
	return guildId and self._channels and self._channels:get(guildId, channelId)
end

function State:getMessage(channelId, messageId)
	return self._messages and self._messages:get(channelId, messageId)
end

----

function State:deleteGuild(guildId)
	return self._guilds and self._guilds:delete(guildId)
end

function State:deleteInvite(code)
	return self._invites and self._invites:delete(code)
end

function State:deleteWebhook(webhookId)
	return self._webhooks and self._webhooks:delete(webhookId)
end

function State:deleteRole(guildId, roleId)
	return self._roles and self._roles:delete(guildId, roleId)
end

function State:deleteEmoji(guildId, emojiId)
	return self._emojis and self._emojis:delete(guildId, emojiId)
end

function State:deleteMember(guildId, userId)
	return self._members and self._members:delete(guildId, userId)
end

function State:deleteBan(guildId, userId)
	return self._bans and self._bans:delete(guildId, userId)
end

function State:deletePresence(guildId, userId)
	return self._presences and self._presences:delete(guildId, userId)
end

function State:deleteChannel(channelId)
	local guildId = channelMap[channelId]
	return guildId and self._channels and self._channels:delete(guildId, channelId)
end

function State:deleteMessage(channelId, messageId)
	return self._messages and self._messages:delete(channelId, messageId)
end

return State
