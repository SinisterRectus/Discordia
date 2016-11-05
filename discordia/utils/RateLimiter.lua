local timer = require('timer')
local Deque = require('./Deque')

local setTimeout = timer.setTimeout
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume

local RateLimiter, _, method = class('RateLimiter', Deque)
RateLimiter.__description = "Extention of Deque that is used by the API class to throttle HTTP requests."

function RateLimiter:__init()
	Deque.__init(self)
end

local function start(self, isRetry)
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

local function stop(self, delay)
	return setTimeout(delay, continue, self)
end

method('start', start, '[isRetry]', "Signals that a request has initiated. If the limiter is in-use, it will enqueue the request's thread.")
method('stop', stop, 'delay', "Signals that a request has finished and that the limiter should wait x milliseconds before resuming the next thread.")

return RateLimiter
