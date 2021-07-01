local class = require('../class')

local ActivityTimestamps, get = class('ActivityTimestamps')

function ActivityTimestamps:__init(data)
	self._start = data.start
	self._stop = data['end'] -- thanks discord
end

function get:start()
	return self._start
end

function get:stop()
	return self._stop
end

return ActivityTimestamps
