local timer = require('timer')
local class = require('../class')

local yield = coroutine.yield
local resume = coroutine.resume
local running = coroutine.running
local setTimeout = timer.setTimeout
local insert, remove = table.insert, table.remove

local Mutex, method = class('Mutex')

function method:__init()
	self._queue = {}
	self._active = false
end

function method:lock()
	if self._active then
		local thread = running()
		insert(self._queue, thread)
		return yield()
	else
		self._active = true
	end
end

function method:unlock()
	local thread = remove(self._queue, 1)
	if thread then
		return assert(resume(thread))
	else
		self._active = false
	end
end

function method:unlockAfter(delay)
	return setTimeout(delay, self.unlock, self)
end

return Mutex
