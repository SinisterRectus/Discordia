local Mutex = require('../libs/utils/Mutex')
local utils = require('./utils')

local sleep = utils.sleep
local assertTrue = utils.assertTrue
local assertError = utils.assertError

local a = 10
local n = 5

local function run(fn, ...)
	return coroutine.wrap(fn)(...)
end

do
	local done = {}
	for i = n, 1, -1 do
		run(function()
			sleep(a * i)
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
			sleep(a * i)
			done[i] = true
			for j = i, n do
				assertTrue(done[j])
			end
			mutex:unlock()
		end)
	end
end

do
	local mutex = Mutex()
	local done = {}
	for i = n, 1, -1 do
		run(function()
			mutex:lock()
			mutex:unlockAfter(a * i)
			done[i] = true
			for j = i, n do
				assertTrue(done[j])
			end
		end)
	end
end

assertError(function() return Mutex():unlockAfter() end, 'expected number, received nil')
assertError(function() return Mutex():unlockAfter(-1) end, 'expected minimum 0, received -1')
