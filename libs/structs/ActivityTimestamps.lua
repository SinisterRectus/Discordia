local class = require('../class')

local Struct = require('./Struct')

local ActivityTimestamps, get = class('ActivityTimestamps', Struct)

function ActivityTimestamps:__init(data)
	Struct.__init(self, data)
end

function get:start()
	return self._start
end

function get:stop()
	return self._end
end

return ActivityTimestamps
