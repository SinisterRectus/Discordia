local class = require('../class')
local helpers = require('../helpers')

local assertResume = helpers.assertResume

local Mutex = class('Mutex')

function Mutex:__init()
	self._queue = {}
	self._owner = nil
end

function Mutex:lock()
	local thread = coroutine.running()
	if self._owner then
		assert(self._owner ~= thread, 'coroutine already locked')
		table.insert(self._queue, thread)
		return coroutine.yield()
	else
		self._owner = thread
	end
end

function Mutex:unlock()
	assert(self._owner == coroutine.running(), 'mutex is not owned by current coroutine')
	if #self._queue > 0 then
		self._owner = table.remove(self._queue, 1)
		return assertResume(self._owner)
	else
		self._owner = nil
	end
end

return Mutex