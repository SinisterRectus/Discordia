local Stopwatch = require('../libs/utils/Stopwatch')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue

coroutine.wrap(function()

	local sw = Stopwatch()

	local t1 = sw:getTime()
	utils.sleep(10)
	sw:stop()
	local t2 = sw:getTime()
	utils.sleep(10)
	local t3 = sw:getTime()
	sw:start()
	utils.sleep(10)
	local t4 = sw:getTime()
	sw:stop()
	sw:reset()
	local t5 = sw:getTime()

	assertTrue(t1 < t2)
	assertEqual(t2, t3)
	assertTrue(t3 < t4)
	assertEqual(t5.value, 0)
	assertEqual(Stopwatch(true):getTime().value, 0)

end)()
