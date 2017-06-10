local uv = require('uv')

local hrtime = uv.hrtime

local Stopwatch, get = require('class')('Stopwatch')

function Stopwatch:__init(stopped)
	local t = hrtime()
	self._initial = t
	self._final = stopped and t or nil
end

function Stopwatch:stop()
	if self._final then return end
	self._final = hrtime()
end

function Stopwatch:start()
	if not self._final then return end
	self._initial = self._initial + hrtime() - self._final
	self._final = nil
end

function Stopwatch:reset()
	self._initial = self._final or hrtime()
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
	return (self._final or hrtime()) - self._initial
end

return Stopwatch
