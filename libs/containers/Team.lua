local Snowflake = require('./Snowflake')
local TeamMember = require('./TeamMember')
local Iterable = require('../utils/Iterable')

local class = require('../class')
local typing = require('../typing')

local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension

local Team, get = class('Team', Snowflake)

function Team:__init(data, client)
	Snowflake.__init(self, data, client)
	self._name = data.name
	self._icon = data.icon
	self._owner_user_id = data.owner_user_id
	for i, v in ipairs(data.members) do
		data.members[i] = TeamMember(v, client)
	end
	self._members = Iterable(data.members, 'id')
end

function Team:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Team has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getTeamIconURL(self.id, self.icon, ext, size)
end

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

function get:ownerId()
	return self._owner_user_id
end

function get:members()
	return self._members
end

return Team
