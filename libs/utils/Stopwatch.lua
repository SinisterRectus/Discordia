--[=[
@c Stopwatch
@t ui
@mt mem
@op stopped boolean
@d Used to measure an elapsed period of time. If a truthy value is passed as an
argument, then the stopwatch will initialize in an idle state; otherwise, it will
initialize in an active state. Although nanosecond precision is available, Lua
can only reliably provide microsecond accuracy due to the lack of native 64-bit
integer support. Generally, milliseconds should be sufficient here.
]=]

local hrtime = require('uv').hrtime
local constants = require('constants')
local Time = require('utils/Time')

local format = string.format

local MS_PER_NS = 1 / (constants.NS_PER_US * constants.US_PER_MS)

local Stopwatch, get = require('class')('Stopwatch')

function Stopwatch:__init(stopped)
	local t = hrtime()
	self._initial = t
	self._final = stopped and t or nil
end

--[=[
@m __tostring
@r string
@d Defines the behavior of the `tostring` function. Returns a string that
represents the elapsed milliseconds for convenience of introspection.
]=]
function Stopwatch:__tostring()
	return format('Stopwatch: %s ms', self.milliseconds)
end

--[=[
@m stop
@r nil
@d Effectively stops the stopwatch.
]=]
function Stopwatch:stop()
	if self._final then return end
	self._final = hrtime()
end

--[=[
@m start
@r nil
@d Effectively starts the stopwatch.
]=]
function Stopwatch:start()
	if not self._final then return end
	self._initial = self._initial + hrtime() - self._final
	self._final = nil
end

--[=[
@m reset
@r nil
@d Effectively resets the stopwatch.
]=]
function Stopwatch:reset()
	self._initial = self._final or hrtime()
end

--[=[
@m getTime
@r Time
@d Returns a new Time object that represents the currently elapsed time. This is
useful for "catching" the current time and comparing its many forms as required.
]=]
function Stopwatch:getTime()
	return Time(self.milliseconds)
end

--[=[@p milliseconds number The total number of elapsed milliseconds. If the
stopwatch is running, this will naturally be different each time that it is accessed.]=]
function get.milliseconds(self)
	local ns = (self._final or hrtime()) - self._initial
	return ns * MS_PER_NS
end

return Stopwatch
