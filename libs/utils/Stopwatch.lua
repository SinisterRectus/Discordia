local uv = require('uv')

local hrtime = uv.hrtime

local Stopwatch, get = require('class')('Stopwatch')

function Stopwatch:__init()
	self._time = hrtime()
end

function Stopwatch:pause()
	if self._cache then return end
	self._cache = hrtime()
end

function Stopwatch:resume()
	if not self._cache then return end
	self._time = self._time + hrtime() - self._cache
	self._cache = nil
end

function Stopwatch:restart()
	self._time = self._cache or hrtime()
end

function get.hours(self)
	return self.nanoseconds / 3.6E12
end

function get.minutes(self)
	return self.nanoseconds / 6.0E10
end

function get.seconds(self)
	return self.nanoseconds * 1E-9
end

function get.milliseconds(self)
	return self.nanoseconds * 1E-6
end

function get.microseconds(self)
	return self.nanoseconds * 1E-3
end

function get.nanoseconds(self)
	return (self._cache or hrtime()) - self._time
end

return Stopwatch
