local Container = require('../utils/Container')

local format = string.format

local Invite, get = class('Invite', Container)

function Invite:__init(data, parent)
	Container.__init(self, data, parent)
	self._guild_id = data.guild.id
	self._channel_id = data.channel.id
	self._guild_name = data.guild.name
	self._channel_name = data.channel.name
	self._channel_type = data.channel.type
	if data.inviter then
		self._inviter = self.client._users:get(data.inviter.id) or self.client._users:new(data.inviter)
	end
	self:_update(data)
end

get('code', '_code')
get('uses', '_uses')
get('maxAge', '_max_age')
get('revoked', '_revoked')
get('maxUses', '_max_uses')
get('temporary', '_temporary')
get('createdAt', '_created_at')
get('inviter', '_inviter') -- no inviter for widget invites
get('guildId', '_guild_id')
get('channelId', '_channel_id')
get('guildName', '_guild_name')
get('channelName', '_channel_name')
get('channelType', '_channel_type')

get('guild', function(self)
	return self.client._guilds:get(self._guild_id)-- may not exist
end)

get('channel', function(self)
	local guild = self.client._guilds:get(self._guild_id)
	if guild then
		return guild._text_channels:get(self._channel_id) or guild._voice_channels:get(self._channel_id) or nil
	end
end)

function Invite:__tostring()
	return format('%s: %s', self.__name, self._code)
end

function Invite:__eq(other)
	return self.__class == other.__class and self._code == other._code
end

function Invite:accept()
	local success, data = self.client._api:acceptInvite(self._code)
	return success
end

function Invite:delete()
	local success, data = self.client._api:deleteInvite(self._code)
	return success
end

return Invite
