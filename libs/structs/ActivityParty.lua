local class = require('../class')

local ActivityParty, get = class('ActivityParty')

function ActivityParty:__init(data)
	self._id = data.id
	self._current_size = data.size and data.size[1]
	self._max_size = data.size and data.size[2]
end

function get:id()
	return self._id
end

function get:currentSize()
	return self._current_size
end

function get:maxSize()
	return self._max_size
end

return ActivityParty
