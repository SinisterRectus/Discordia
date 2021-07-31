local class = require('../class')

local Struct = require('./Struct')

local ActivityParty, get = class('ActivityParty', Struct)

function ActivityParty:__init(data)
	Struct.__init(self, data)
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
