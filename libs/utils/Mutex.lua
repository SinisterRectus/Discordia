local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local yield, running = coroutine.yield, coroutine.running
local setTimeout = helpers.setTimeout
local insert, remove = table.insert, table.remove
local checkNumber = typing.checkNumber
local assertResume = helpers.assertResume

local Mutex = class('Mutex')

function Mutex:__init()
	self._queue = {}
	self._active = false
end

function Mutex:lock(prepend)
	if self._active then
		local thread = running()
		if prepend then
			insert(self._queue, 1, thread)
		else
			insert(self._queue, thread)
		end
		return yield()
	else
		self._active = true
	end
end

function Mutex:unlock()
	local thread = remove(self._queue, 1)
	if thread then
		return assertResume(thread)
	else
		self._active = false
	end
end

function Mutex:unlockAfter(delay)
	return setTimeout(checkNumber(delay, 10, 0), self.unlock, self)
end

return Mutex
