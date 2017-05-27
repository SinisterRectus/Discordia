local Snowflake = require('../Snowflake')

local Invite = class('Invite', Snowflake)

function Invite:__init(data, parent)
	Snowflake.__init(self, data, parent)

	self.code = data.code
	self.server = Guild
	self.client = server.client
	self.xkcdpass = data.xkcdpass
	self.channel = Guild:getChannelById(data.channel.id)

	self.inviter = Guild:getMemberById(data.inviter.id) -- a user object
	self.uses = data.uses -- integer
	self.maxUses = data.maxUses -- integer
	self.maxAge = data.maxAge -- seconds
	self.temporary = data.temporary -- bool
	self.createdAt = data.createdAt -- datetime
	self.revoked = data.revoked -- bool
end

function Invite:__tostring()
	return string.format('%s: %s', self.__name, self.code)
end

function Invite:accept(payload)
	return self.client.api:acceptInvite(self.id, payload)
end

function Invite:delete()
	return self.client.api:deleteInvite(self.id)
end

return Invite
