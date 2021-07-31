local Container = require('./Container')

local class = require('../class')

local TeamMember, get = class('TeamMember', Container)

function TeamMember:__init(data, client)
	Container.__init(self, data, client)
	self._user = client.state:newUser(data.user)
end

function TeamMember:__eq(other)
	return self.teamId == other.teamId and self.user.id == other.user.id
end

function TeamMember:toString()
	return self.teamId .. ':' .. self.user.id
end

function get:id()
	return self.user.id
end

function get:membershipState()
	return self._membership_state
end

function get:permissions()
	return self._permissions
end

function get:teamId()
	return self._team_id
end

function get:user()
	return self._user
end

return TeamMember
