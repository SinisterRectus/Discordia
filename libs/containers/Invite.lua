local Container = require('./Container')
local User = require('./User')

local class = require('../class')

local Invite, get = class('Invite', Container)

function Invite:__init(data, client)
	Container.__init(self, client)
	self._code = data.code
	self._inviter = data.inviter and User(data.inviter, client) or nil
	self._approximate_presence_count = data.approximate_presence_count -- with_counts
	self._approximate_member_count = data.approximate_member_count -- with_counts
	self._uses = data.uses
	self._max_uses = data.max_uses
	self._max_age = data.max_age
	self._temporary = data.temporary
	self._created_at = data.created_at
	-- TODO: data.channel and data.guild
end

function Invite:__eq(other)
	return self.code == other.code
end

function Invite:delete()
	local data, err = self.client.api:deleteInvite(self._code)
	if data then
		return true
	else
		return false, err
	end
end

function get:code()
	return self._code
end

function get:inviter()
	return self._inviter
end

function get:uses()
	return self._uses
end

function get:maxUses()
	return self._max_uses
end

function get:maxAge()
	return self._max_age
end

function get:temporary()
	return self._temporary
end

function get:createdAt()
	return self._createdAt
end

function get:approximatePresenceCount()
	return self._approximate_presence_count
end

function get:approximateMemberCount()
	return self._approximate_member_count
end

return Invite
