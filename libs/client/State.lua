-- local AuditLogEntry = require('../containers/AuditLogEntry')
-- local Ban = require('../containers/Ban')
local Channel = require('../containers/Channel')
local Emoji = require('../containers/Emoji')
local Guild = require('../containers/Guild')
local Invite = require('../containers/Invite')
local Member = require('../containers/Member')
local Message = require('../containers/Message')
local Role = require('../containers/Role')
local User = require('../containers/User')
local Webhook = require('../containers/Webhook')

local class = require('../class')

local State = class('State')

local roleMap = {} -- roleId -> guildId
local emojiMap = {} -- roleId -> guildId
local memberMap = {} -- memberId -> guildId
local channelMap = {} -- channelId -> guildId
local messageMap = {} -- messageId -> channelId

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
	self._roles = auto()
	self._emojis = auto()
	self._members = auto()
	self._channels = auto()
	self._messages = auto()

end

function State:newUser(data)
	local user = User(data, self._client)
	self._users[data.id] = user
	return user
end

function State:newGuild(data)
	local guild = Guild(data, self._client)
	self._guilds[data.id] = guild
	return guild
end

function State:newInvite(data)
	local invite = Invite(data, self._client)
	self._invites[data.id] = invite
	return invite
end

function State:newWebhook(data)
	local webhook = Webhook(data, self._client)
	self._webhooks[data.id] = webhook
	return webhook
end

function State:newRole(guildId, data)
	data.guild_id = guildId
	roleMap[data.id] = guildId
	local role = Role(data, self._client)
	self._roles[guildId][data.id] = role
	return role
end

function State:newEmoji(guildId, data)
	data.guild_id = guildId
	emojiMap[data.id] = guildId
	local emoji = Emoji(data, self._client)
	self._emojis[guildId][data.id] = emoji
	return emoji
end

function State:newMember(guildId, data)
	data.guild_id = guildId
	memberMap[data.user.id] = guildId
	local member = Member(data, self._client)
	self._members[guildId][data.user.id] = member
	return member
end

function State:newChannel(data)
	local guildId = data.guild_id or '@me'
	channelMap[data.id] = guildId
	local channel = Channel(data, self._client)
	self._channels[guildId][data.id] = channel
	return channel
end

function State:newMessage(channelId, data, gateway)
	local guildId = gateway and (data.guild_id or '@me') or channelMap[channelId]
	if guildId == nil then
		local channel, err = self._client:getChannel(channelId)
		if channel then
			guildId = channel.guildId or '@me'
			channelMap[channelId] = guildId
		else
			return nil, err
		end
	end
	if guildId ~= '@me' then
		data.guild_id = guildId
	end
	messageMap[data.id] = channelId
	local message = Message(data, self._client)
	self._messages[channelId][data.id] = message
	return message
end

function State:updateMessage(data)
	local old = self:getMessage(data.id)
	if old then
		local new = class.copy(old)
		new:_update(data)
		self.messages[data.channel_id][data.id] = new
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

function State:getRole(roleId)
	local guildId = roleMap[roleId]
	return guildId and self._roles[guildId][roleId]
end

function State:getEmoji(emojiId)
	local guildId = emojiMap[emojiId]
	return guildId and self._emojis[guildId][emojiId]
end

function State:getMember(memberId)
	local guildId = memberMap[memberId]
	return guildId and self._members[guildId][memberId]
end

function State:getChannel(channelId)
	local guildId = channelMap[channelId]
	return guildId and self._channels[guildId][channelId]
end

function State:getMessage(messageId)
	local channelId = messageMap[messageId]
	return channelId and self._messages[channelId][messageId]
end

return State
