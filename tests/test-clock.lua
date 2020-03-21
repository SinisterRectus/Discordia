local Clock = require('../libs/utils/Clock')
local utils = require('./utils')

local clock = Clock()

local prev = os.time()
clock:once('sec', function(now)
	utils.assertTrue(os.time(now) > prev)
	clock:stop()
end)

clock:start()
