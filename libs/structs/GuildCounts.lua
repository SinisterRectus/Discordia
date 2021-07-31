local class = require('../class')
local Struct = require('./Struct')

local GuildCounts, get = class('GuildCounts', Struct)

function GuildCounts:__init(data)
	Struct.__init(self, data)
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
