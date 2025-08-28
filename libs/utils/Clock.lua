local helpers = require('../helpers')
local class = require('../class')
local Emitter = require('./Emitter')

local Clock = class('Clock', Emitter)

function Clock:__init()
	Emitter.__init(self)
	self._interval = nil
end

function Clock:start(utc)
	if self._interval then return end
	local fmt = utc and '!*t' or '*t'
	local prev = os.date(fmt)
	self._interval = helpers.setInterval(1000, function()
		local now = os.date(fmt)
		for k, v in pairs(now) do
			if v ~= prev[k] then
				self:emit(k, now)
			end
		end
		prev = now
	end)
end

function Clock:stop()
	if not self._interval then return end
	helpers.clearTimer(self._interval)
	self._interval = nil
end

return Clock