local Mutex = require('../libs/utils/Mutex')
local utils = require('./utils')

local sleep = utils.sleep
local assertTrue = utils.assertTrue
local assertError = utils.assertError

local a = 10
local n = 3

local function run(fn, ...)
	return coroutine.wrap(fn)(...)
end

do
	local done = {}
	for i = n, 1, -1 do
		run(function()
			sleep(a ^ i)
			done[i] = true
			for j = 1, i do
				assertTrue(done[j])
			end
		end)
	end
end

do
	local mutex = Mutex()
	local done = {}
	for i = n, 1, -1 do
		run(function()
			mutex:lock()
			sleep(a ^ i)
			done[i] = true
			for j = i, n do
				assertTrue(done[j])
			end
			mutex:unlock()
		end)
	end
end

assertError(function()
	local mutex = Mutex()
	mutex:lock()
	mutex:lock()
end, 'coroutine already locked')

assertError(function()
	local mutex = Mutex()
	mutex:unlock()
end, 'mutex is not owned by current coroutine')

assertError(function()
	local mutex = Mutex()
	mutex:lock()
	run(mutex.unlock, mutex)
end, 'mutex is not owned by current coroutine')