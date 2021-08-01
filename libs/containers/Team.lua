local Snowflake = require('./Snowflake')

local class = require('../class')
local typing = require('../typing')

local checkImageSize = typing.checkImageSize
local checkImageExtension = typing.checkImageExtension

local Team, get = class('Team', Snowflake)

function Team:__init(data, client)
	Snowflake.__init(self, data, client)
	self._members = data.members and client.state:newTeamMembers(data.members)
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
