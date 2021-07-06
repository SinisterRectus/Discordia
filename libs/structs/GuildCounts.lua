local class = require('../class')

local GuildCounts, get = class('GuildCounts')

function GuildCounts:__init(data)
	self._max_members = data.max_members
	self._max_presences = data.max_presences
	self._approximate_member_count = data.approximate_member_count
	self._approximate_presence_count = data.approximate_presence_count
end

function get:maxMembers()
	return self._max_members
end

function get:maxPresences()
	return self._max_presences
end

function get:approximateMemberCount()
	return self._approximate_member_count
end

function get:approximatePresenceCount()
	return self._approximate_presence_count
end

return GuildCounts
