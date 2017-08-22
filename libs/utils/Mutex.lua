local Deque = require('./Deque')
local timer = require('timer')

local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running
local setTimeout = timer.setTimeout

local Mutex = require('class')('Mutex', Deque)

--[[
@class Mutex

Mutual exclusion class used to control Lua coroutine execution order.
]]
function Mutex:__init()
	Deque.__init(self)
	self._active = false
end

--[[
@method lock
@param prepend: boolean

If the mutex is not active (if a coroutine is not queued), this will activate
the mutex; otherwise, this will yield and queue the current coroutine.
]]
function Mutex:lock(prepend)
	if self._active then
		if prepend then
			return yield(self:pushLeft(running()))
		else
			return yield(self:pushRight(running()))
		end
	else
		self._active = true
	end
end

--[[
@method unlock

If the mutex is active (if a coroutine is queued), this will dequeue and resume
the next available coroutine; otherwise, this will deactive the mutex.
]]
function Mutex:unlock()
	if self:getCount() > 0 then
		return assert(resume(self:popLeft()))
	else
		self._active = false
	end
end

--[[
@method unlockAfter
@param delay: number
@ret userdata

Asynchronously unlocks the mutex after a specified time in milliseconds. The
relevant `uv_timer` object is returned.
]]
local unlock = Mutex.unlock
function Mutex:unlockAfter(delay)
	return setTimeout(delay, unlock, self)
end

return Mutex
