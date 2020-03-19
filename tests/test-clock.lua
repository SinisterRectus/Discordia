local Clock = require('../libs/utils/Clock')
local utils = require('./utils')

local clock = Clock()

local prev = os.time()
clock:once('sec', function(now)
	utils.assertEqual(os.time(now), prev + 1)
	clock:stop()
end)

clock:start()
