--[=[@c Clock x Emitter ...]=]

local timer = require('timer')
local Emitter = require('utils/Emitter')

local date = os.date
local setInterval, clearInterval = timer.setInterval, timer.clearInterval

local Clock = require('class')('Clock', Emitter)

function Clock:__init()
	Emitter.__init(self)
end

--[=[
@m start
@p utc boolean
@r void
@d ...
]=]
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

--[=[
@m stop
@r void
@d ...
]=]
function Clock:stop()
	if not self._interval then return end
	clearInterval(self._interval)
	self._interval = nil
end

return Clock
