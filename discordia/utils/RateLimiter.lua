local timer = require('timer')
local Deque = require('../utils/Deque')

local setTimeout = timer.setTimeout
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume

local RateLimiter = class('RateLimiter', Deque)

function RateLimiter:__init()
	Deque.__init(self)
end

function RateLimiter:start(isRetry)
	if self.locked then
		if isRetry then
			return yield(self:pushLeft(running()))
		else
			return yield(self:pushRight(running()))
		end
	else
		self.locked = true
	end
end

local function continue(limiter)
	if limiter:getCount() > 0 then
		return resume(limiter:popLeft())
	else
		limiter.locked = false
	end
end

function RateLimiter:stop(delay)
	return setTimeout(delay, continue, self)
end

return RateLimiter
