local timer = require('timer')
local Deque = require('./Deque')

local setTimeout = timer.setTimeout
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume

local Mutex, property, method = class('Mutex', Deque)
Mutex.__description = "Mutual exclusion class for coroutines."

function Mutex:__init()
	Deque.__init(self)
	self._active = false
end

local function lock(self, isRetry)
	if self._active then
		if isRetry then
			return yield(self:pushLeft(running()))
		else
			return yield(self:pushRight(running()))
		end
	else
		self._active = true
	end
end

local function unlock(self)
	if self:getCount() > 0 then
		return resume(self:popLeft())
	else
		self._active = false
	end
end

local function unlockAfter(self, delay)
	return setTimeout(delay, unlock, self)
end

property('active', '_active', nil, 'boolean', 'Indicates whether the mutex is in use.')

method('lock', lock, '[isRetry]', "Activates the mutex if not already active, or, enqueues and yields the current coroutine.")
method('unlock', unlock, nil, "Dequeues and resumes a coroutine if one exists, or, deactives the mutex.")
method('unlockAfter', unlockAfter, 'delay', "Unlocks the mutex after x miliseconds.")

return Mutex
