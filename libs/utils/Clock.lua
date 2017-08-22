local timer = require('timer')
local Emitter = require('utils/Emitter')

local date = os.date
local setInterval, clearInterval = timer.setInterval, timer.clearInterval

local Clock = require('class')('Clock', Emitter)

--[[
@class Clock x Emitter

Used to periodically execute code according to the ticking of the system clock
rather than an arbitrary interval.
]]
function Clock:__init()
	Emitter.__init(self)
end

--[[
@method start
@param [utc]: boolean

Starts the main loop for the clock. If a truthy argument is passed, then UTC
time is used; otherwise, local time is used. As the clock ticks, an event is
emitted for every `os.date` value change. The event name is the key of the value
that changed and the event argument is the corresponding date table.
]]
function Clock:start(utc)
	if self._interval then return end
	local fmt = utc and '!*t' or '*t'
	local prev = date(fmt)
	self._interval = setInterval(1000, function()
		local now = date(fmt)
		for k, v in pairs(now) do
			if v ~= prev[k] then
				self:emit(k, now)
			end
		end
		prev = now
	end)
end

--[[
@method stop

Stops the main loop for the clock.
]]
function Clock:stop()
	if not self._interval then return end
	clearInterval(self._interval)
	self._interval = nil
end

return Clock
