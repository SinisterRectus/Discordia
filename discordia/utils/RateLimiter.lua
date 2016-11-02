local timer = require('timer')
local Deque = require('./Deque')

local setTimeout = timer.setTimeout
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume

local RateLimiter = class('RateLimiter', Deque)

function RateLimiter:__init()
	Deque.__init(self)
end

function RateLimiter:start(isRetry)
	if self._locked then
		if isRetry then
			return yield(self:pushLeft(running()))
		else
			return yield(self:pushRight(running()))
		end
	else
		self._locked = true
	end
end

local function continue(self)
	if self:getCount() > 0 then
		return resume(self:popLeft())
	else
		self._locked = false
	end
end

function RateLimiter:stop(delay)
	return setTimeout(delay, continue, self)
end

return RateLimiter
