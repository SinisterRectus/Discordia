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
		self._inviter = self._parent._users:get(data.inviter.id) or self._parent._users:new(data.inviter)
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

function Invite:__tostring()
	return format('%s: %s', self.__name, self._code)
end

function Invite:__eq(other)
	return self.__class == other.__class and self._code == other._code
end

function Invite:accept()
	local success, data = self._parent._api:acceptInvite(self._code)
	return success
end

function Invite:delete()
	local success, data = self._parent._api:deleteInvite(self._code)
	return success
end

return Invite
