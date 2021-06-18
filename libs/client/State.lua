local AuditLogEntry = require('../containers/AuditLogEntry')
local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local Emoji = require('../containers/Emoji')
local Guild = require('../containers/Guild')
local Invite = require('../containers/Invite')
local Member = require('../containers/Member')
local Message = require('../containers/Message')
local Presence = require('../containers/Presence')
local Role = require('../containers/Role')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')

local Iterable = require('./Iterable')

local class = require('../class')

local State = class('State')

local channelMap = {} -- channelId -> guildId

function State:__init(client)
	self._client = assert(client)
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
	return User(data, self._client)
end

function State:newUsers(data)
	for i, v in ipairs(data) do
		data[i] = self:newUser(v)
	end
	return Iterable(data, 'id')
end

function State:newGuild(data)
	return Guild(data, self._client)
end

function State:newGuilds(data)
	for i, v in ipairs(data) do
		data[i] = self:newGuild(v)
	end
	return Iterable(data, 'id')
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

function State:newWebhook(data)
	return Webhook(data, self._client)
end

function State:newWebhooks(data)
	for i, v in ipairs(data) do
		data[i] = self:newWebhook(v)
	end
	return Iterable(data, 'id')
end

function State:newRole(guildId, data)
	data.guild_id = guildId
	return Role(data, self._client)
end

function State:newRoles(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newRole(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newEmoji(guildId, data)
	data.guild_id = guildId
	return Emoji(data, self._client)
end

function State:newEmojis(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newEmoji(guildId, v)
	end
	return Iterable(data, 'id')
end

function State:newMember(guildId, data)
	data.guild_id = guildId
	return Member(data, self._client)
end

function State:newMembers(guildId, data)
	for i, v in ipairs(data) do
		data[i] = self:newMember(guildId, v)
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
	channelMap[data.id] = data.guild_id or '@me'
	return Channel(data, self._client)
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
		local guildId = self:getGuildId(channelId)
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

return State
