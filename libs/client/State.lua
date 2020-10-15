-- local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local Emoji = require('../containers/Emoji')
local Guild = require('../containers/Guild')
local Invite = require('../containers/Invite')
local Member = require('../containers/Member')
local Message = require('../containers/Message')
local PermissionOverwrite = require('../containers/PermissionOverwrite')
local Presence = require('../containers/Presence')
local Role = require('../containers/Role')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')

local class = require('../class')

local State = class('State')

local channelMap = {} -- channelId -> guildId

local function auto()
	return setmetatable({}, {__index = function(self, k)
		self[k] = {}
		return self[k]
	end})
end

function State:__init(client)

	self._client = assert(client)

	self._users = {}
	self._guilds = {}
	self._invites = {}
	self._webhooks = {}
	self._bans = auto()
	self._roles = auto()
	self._emojis = auto()
	self._members = auto()
	self._channels = auto()
	self._messages = auto()
	self._presences = auto()
	self._overwrites = auto()

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
	local user = self._users[data.id]
	if user then
		user:__init(data, self._client)
	else
		user = User(data, self._client)
	end
	self._users[data.id] = user
	return user
end

function State:newUsers(data)
	for i, v in ipairs(data) do
		data[i] = self:newUser(v)
	end
	return data
end

function State:newGuild(data)
	local guild = self._guilds[data.id]
	if guild then
		guild:__init(data, self._client)
	else
		guild = Guild(data, self._client)
	end
	self._guilds[data.id] = guild
	return guild
end

function State:newGuilds(data)
	for i, v in ipairs(data) do
		data[i] = self:newGuild(v)
	end
	return data
end

function State:newInvite(data)
	local invite = self._invites[data.code]
	if invite then
		invite:__init(data, self._client)
	else
		invite = Invite(data, self._client)
	end
	self._invites[data.code] = invite
	return invite
end

function State:newInvites(data)
	for i, v in ipairs(data) do
		data[i] = self:newInvite(v)
	end
	return data
end

function State:newWebhook(data)
	local webhook = self._webhooks[data.id]
	if webhook then
		webhook:__init(data, self._client)
	else
		webhook = Webhook(data, self._client)
	end
	self._webhooks[data.id] = webhook
	return webhook
end

function State:newWebhooks(data)
	for i, v in ipairs(data) do
		data[i] = self:newWebhook(v)
	end
	return data
end

function State:newRole(guildId, data)
	data.guild_id = guildId
	local role = self._roles[guildId][data.id]
	if role then
		role:__init(data, self._client)
	else
		role = Role(data, self._client)
		self._roles[guildId][data.id] = role
	end
	return role
end

function State:newRoles(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newRole(guildId, v)
	end
	return data
end

function State:newEmoji(guildId, data)
	data.guild_id = guildId
	local emoji = self._emojis[guildId][data.id]
	if emoji then
		emoji:__init(data, self._client)
	else
		emoji = Emoji(data, self._client)
		self._emojis[guildId][data.id] = emoji
	end
	return emoji
end

function State:newEmojis(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newEmoji(guildId, v)
	end
	return data
end

function State:newMember(guildId, data)
	data.guild_id = guildId
	local member = self._members[guildId][data.user.id]
	if member then
		member:__init(data, self._client)
	else
		member = Member(data, self._client)
		self._members[guildId][data.user.id] = member
	end
	return member
end

function State:newMembers(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newMember(guildId, v)
	end
	return data
end

function State:newBan(guildId, data)
	data.guild_id = guildId
	local ban = self._bans[guildId][data.user.id]
	if ban then
		ban:__init(data, self._client)
	else
		ban = Ban(data, self._client)
		self._bans[guildId][data.user.id] = ban
	end
	return ban
end

function State:newBans(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newBan(guildId, v)
	end
	return data
end

function State:newPresence(guildId, data)
	data.guild_id = guildId
	local presence = self._presences[guildId][data.user.id]
	if presence then
		presence:__init(data, self._client)
	else
		presence = Presence(data, self._client)
		self._presences[guildId][data.user.id] = presence
	end
	return presence
end

function State:newPresences(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newPresence(guildId, v)
	end
	return data
end

function State:newChannel(data)
	local guildId = data.guild_id or '@me'
	local channel = self._channels[guildId][data.id]
	if channel then
		channel:__init(data, self._client)
	else
		channelMap[data.id] = guildId
		channel = Channel(data, self._client)
	end
	self._channels[guildId][data.id] = channel
	return channel
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
	local message = self._messages[channelId][data.id]
	if message then
		message:__init(data, self._client)
	else
		message = Message(data, self._client)
		self._messages[channelId][data.id] = message
	end
	return message
end

function State:newMessages(data, gateway)
	for i, v in ipairs(data) do
		data[i] = self:newMessage(v, gateway)
	end
	return data
end

function State:newOverwrite(channelId, data)
	data.channel_id = channelId
	local overwrite = self._overwrites[channelId][data.id]
	if overwrite then
		overwrite:__init(data, self._client)
	else
		overwrite = PermissionOverwrite(data, self._client)
		self._overwrites[channelId][data.id] = overwrite
	end
	return overwrite
end

function State:newOverwrites(channelId, data)
	for i, v in ipairs(data) do
		data[i] = self:newOverwrite(channelId, v)
	end
	return data
end

function State:updateMessage(data)
	local old = self._messages[data.channel_id][data.id]
	if old then
		local new = class.copy(old)
		new:_update(data)
		self._messages[data.channel_id][data.id] = new
	end
end

function State:getUser(userId)
	return self._users[userId]
end

function State:getGuild(guildId)
	return self._guilds[guildId]
end

function State:getInvite(code)
	return self._invites[code]
end

function State:getWebhook(webhookId)
	return self._webhooks[webhookId]
end

function State:getRole(guildId, roleId)
	return self._roles[guildId][roleId]
end

function State:getEmoji(guildId, emojiId)
	return self._emojis[guildId][emojiId]
end

function State:getMember(guildId, userId)
	return self._members[guildId][userId]
end

function State:getBan(guildId, userId)
	return self._bans[guildId][userId]
end

function State:getPresence(guildId, userId)
	return self._presences[guildId][userId]
end

function State:getChannel(channelId)
	local guildId = channelMap[channelId]
	return guildId and self._channels[guildId][channelId]
end

function State:getMessage(channelId, messageId)
	return self._messages[channelId][messageId]
end

return State
