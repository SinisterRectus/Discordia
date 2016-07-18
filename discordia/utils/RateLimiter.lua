local timer = require('timer')
local Deque = require('./Deque')
local Stopwatch = require('./Stopwatch')

local RateLimiter, accessors = class('RateLimiter')

function RateLimiter:__init(limit, delay)
	self.watch = Stopwatch(delay * 1E6)
	self.finished = Deque()
	self.limit = limit
	self.delay = delay
end

function RateLimiter:start()
	while self.lock or self:getSum() + self.watch:getMilliseconds() < self.delay do
		timer.sleep(self.delay / 10)
	end
	self.lock = true
end

function RateLimiter:stop()
	self.finished:pushRight(self.watch:getMilliseconds())
	if self.finished:getCount() == self.limit then
		self.finished:popLeft()
	end
	self.watch:restart()
	self.lock = false
end

function RateLimiter:getSum()
	local sum = 0
	for n in self.finished:iter() do
		sum = sum + n
	end
	return sum
end

return RateLimiter
