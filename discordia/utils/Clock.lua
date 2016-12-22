local Emitter = require('./Emitter')
local timer = require('timer')

local date = os.date
local setInterval, clearInterval = timer.setInterval, timer.clearInterval

local Clock, _, method = class('Clock', Emitter)
Clock.__description = 'Event emitter for system clock changes.'

function Clock:__init()
	Emitter.__init(self)
end

local function start(self, utc)
	if self._interval then return end
	local fmt = utc and '!*t' or '*t'
	local prev = date(fmt)
	self._interval = setInterval(300, function()
		local now = date(fmt)
		for k, v in pairs(now) do
			if v ~= prev[k] then
				self:emit(k, now)
			end
		end
		prev = now
	end)
end

local function stop(self)
	if not self._interval then return end
	clearInterval(self._interval)
	self._interval = nil
end

method('start', start, '[utc]', "Starts the clock. For UTC time keeping, pass `true`.")
method('stop', stop, nil, "Stops the clock. Event listeners are not removed.")

return Clock
