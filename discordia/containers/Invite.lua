local Container = require('../utils/Container')

local format = string.format

local Invite, accessors = class('Invite', Container)

accessors.guild = function(self) return self.parent.guilds:get(self.guildId) end -- may not exist
accessors.channel = function(self) -- may not exist
	local guild = self.parent.guilds:get(self.guildId)
	if guild then
		return guild.textChannels:get(self.channelId) or guild.voiceChannels:get(self.channelId) or nil
	end
end

function Invite:__init(data, parent)
	Container.__init(self, parent)
	self.code = data.code
	self.guildId = data.guild.id
	self.channelId = data.channel.id
	self.guildName = data.guild.name
	self.channelName = data.channel.name
	self.channelType = data.channel.type
	self.uses = data.uses
	self.maxAge = data.max_age
	self.revoked = data.revoked
	self.maxUses = data.max_uses
	self.temporary = data.temporary
	self.createdAt = data.created_at
	if data.inviter then -- no inviter for widget invites
		self.inviter = self.client.users:get(data.inviter.id) or self.client.users:new(data.inviter)
	end
end

function Invite:__tostring()
	return format('%s: %s', self.__name, self.code)
end

function Invite:__eq(other)
	return self.__class == other.__class and self.code == other.code
end

function Invite:accept()
	local success, data = self.client.api:acceptInvite(self.code)
	return success
end

function Invite:delete()
	local success, data = self.client.api:deleteInvite(self.code)
	return success
end

return Invite
