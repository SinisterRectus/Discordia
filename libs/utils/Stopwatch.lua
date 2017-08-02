local hrtime = require('uv').hrtime
local constants = require('constants')

local NS_PER_US = constants.NS_PER_US
local NS_PER_MS = NS_PER_US * constants.US_PER_MS
local NS_PER_S = NS_PER_MS * constants.MS_PER_S
local NS_PER_MIN = NS_PER_S * constants.S_PER_MIN
local NS_PER_HOUR = NS_PER_MIN * constants.MIN_PER_HOUR

local Stopwatch , get = require('class')('Stopwatch')

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
	return self.nanoseconds / NS_PER_HOUR
end

function get.minutes(self)
	return self.nanoseconds / NS_PER_MIN
end

function get.seconds(self)
	return self.nanoseconds / NS_PER_S
end

function get.milliseconds(self)
	return self.nanoseconds / NS_PER_MS
end

function get.microseconds(self)
	return self.nanoseconds / NS_PER_US
end

function get.nanoseconds(self)
	return (self._final or hrtime()) - self._initial
end

return Stopwatch
