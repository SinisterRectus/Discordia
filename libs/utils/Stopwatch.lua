local hrtime = require('uv').hrtime
local constants = require('constants')
local Time = require('utils/Time')

local NS_PER_US = constants.NS_PER_US
local NS_PER_MS = NS_PER_US * constants.US_PER_MS

local Stopwatch, get = require('class')('Stopwatch')

function Stopwatch:__init(stopped)
	local t = hrtime()
	self._initial = t
	self._final = stopped and t or nil
end

--[[
@method stop
]]
function Stopwatch:stop()
	if self._final then return end
	self._final = hrtime()
end

--[[
@method start
]]
function Stopwatch:start()
	if not self._final then return end
	self._initial = self._initial + hrtime() - self._final
	self._final = nil
end

--[[
@method reset
]]
function Stopwatch:reset()
	self._initial = self._final or hrtime()
end

--[[
@method getTime
@ret Time
]]
function Stopwatch:getTime()
	return Time(self.milliseconds)
end

--[[
@property value: number
]]
function get.milliseconds(self)
	local ns = (self._final or hrtime()) - self._initial
	return ns / NS_PER_MS
end

return Stopwatch
