local Clock = require('../libs/utils/Clock')
local utils = require('./utils')

local t = os.time()

local clock1 = Clock(true)
clock1:on('sec', function(now)
	utils.assertTrue(os.time(now) > t)
	clock1:stop()
end)
clock1:start()

local clock2 = Clock(false)
clock2:on('sec', function(now)
	utils.assertTrue(os.time(now) > t)
	clock2:stop()
end)
clock2:start()