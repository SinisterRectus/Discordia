--[=[@c Mutex ...]=]

local Deque = require('./Deque')
local timer = require('timer')

local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running
local setTimeout = timer.setTimeout

local Mutex = require('class')('Mutex', Deque)

function Mutex:__init()
	Deque.__init(self)
	self._active = false
end

--[=[
@m lock
@op prepend boolean
@r void
@d ...
]=]
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

--[=[
@m unlock
@r void
@d ...
]=]
function Mutex:unlock()
	if self:getCount() > 0 then
		return assert(resume(self:popLeft()))
	else
		self._active = false
	end
end

--[=[
@m unlockAfter
@p delay number
@r uv_timer
@d ...
]=]
local unlock = Mutex.unlock
function Mutex:unlockAfter(delay)
	return setTimeout(delay, unlock, self)
end

return Mutex
