local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local setTimeout = helpers.setTimeout
local assertResume = helpers.assertResume
local checkNumber = typing.checkNumber

local Mutex = class('Mutex')

function Mutex:__init()
	self._queue = {}
	self._active = false
end

function Mutex:lock(prepend)
	if self._active then
		local thread = coroutine.running()
		if prepend then
			table.insert(self._queue, 1, thread)
		else
			table.insert(self._queue, thread)
		end
		return coroutine.yield()
	else
		self._active = true
	end
end

function Mutex:unlock()
	if self._active then
		local thread = table.remove(self._queue, 1)
		if thread then
			return assertResume(thread)
		else
			self._active = false
		end
	end
end

function Mutex:unlockAfter(delay)
	return setTimeout(checkNumber(delay, 10, 0), self.unlock, self)
end

return Mutex