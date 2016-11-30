local Container = require('../utils/Container')

local format = string.format

local Invite, property, method = class('Invite', Container)
Invite.__description = "Represents a Discord invitation for joining guilds."

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
	self._guild_id = data.guild.id
	self._channel_id = data.channel.id
	self._guild_name = data.guild.name
	self._channel_name = data.channel.name
	self._channel_type = data.channel.type
	if data.inviter then
		self._inviter = self._parent._users:get(data.inviter.id) or self._parent._users:new(data.inviter)
	end
end

function Invite:__tostring()
	return format('%s: %s', self.__name, self._code)
end

function Invite:__eq(other)
	return self.__name == other.__name and self._code == other._code
end

local function getRevoked(self)
	return self._revoked or false
end

local function accept(self)
	return (self._parent._api:acceptInvite(self._code))
end

local function delete(self)
	return (self._parent._api:deleteInvite(self._code))
end

property('code', '_code', nil, 'string', "Invite identifying code")
property('uses', '_uses', nil, 'number', "How many times this invite has been used")
property('maxAge', '_max_age', nil, 'number', "How many seconds since creation the invite lasts")
property('revoked', '_revoked', getRevoked, 'boolean', "Whether the invite is revoked and invalid")
property('maxUses', '_max_uses', nil, 'number', "How many times the invite can be used")
property('temporary', '_temporary', nil, 'boolean', "Whether the invite grants temporary guild membership")
property('createdAt', '_created_at', nil, 'string', "When the invite was created")
property('inviter', '_inviter', nil, 'User', "The user that created the invite (nil for widget invites)")
property('guildId', '_guild_id', nil, 'string', "Snowflake ID of the guild for which the invite exists")
property('channelId', '_channel_id', nil, 'string', "Snowflake ID of the channel for which the invite exists")
property('guildName', '_guild_name', nil, 'string', "Name of the guild for which the invite exists")
property('channelName', '_channel_name', nil, 'string', "Name of the channel for which the invite exists")
property('channelType', '_channel_type', nil, 'string', "Type of the channel for which the invite exists")

method('accept', accept, nil, "Joins the guild and channel for which the invite exists (non-bots only).")
method('delete', delete, nil, "Revokes and deletes the invite.")

return Invite
