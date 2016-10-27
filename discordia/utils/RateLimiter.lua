local timer = require('timer')
local Deque = require('./Deque')

local setTimeout = timer.setTimeout
local date, time, difftime = os.date, os.time, os.difftime
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume

local months = {
	Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
	Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12
}
local pattern = '(%a-), (%d-) (%a-) (%d-) (%d-):(%d-):(%d-) GMT'

local function offset(str)
	local wday, day, month, year, hour, min, sec = str:match(pattern)
	local serverDate = {
		day = day, month = months[month], year = year,
		hour = hour, min = min, sec = sec,
	}
	local clientDate = date('!*t')
	clientDate.isdst = date('*t').isdst -- I hope this works right...
	return difftime(time(clientDate), time(serverDate))
end

local function continue(limiter)
	local queue = limiter.queue
	if queue:getCount() > 0 then
		resume(queue:popLeft())
	else
		limiter.locked = false
	end
end

local RateLimiter, accessors = class('RateLimiter')

function RateLimiter:__init()
	self.queue = Deque()
	self.new = true -- debug
end

function RateLimiter:open()
	if self.locked then
		yield(self.queue:pushRight(running()))
	else
		self.locked = true
	end
end

function RateLimiter:close(response)

	local headers = {}
	for i, v in ipairs(response) do
		headers[v[1]] = v[2]
	end

	local reset = tonumber(headers['X-RateLimit-Reset'])
	local limit = tonumber(headers['X-RateLimit-Limit'])
	local remaining = tonumber(headers['X-RateLimit-Remaining'])

	local delay = 500

	if reset and limit and remaining then

		local offset = offset(headers['Date'])
		if math.abs(offset) > 10 then failure.time(offset) end -- debug

		if self.new then -- debug, need to make sure the routes are correct
			self.new = false
			assert(remaining == limit - 1, self.route)
		end

		local dt = difftime(reset + offset, time())

		if math.abs(dt) > 60 then failure('rate limit delay ' .. dt) end -- debug

		-- delay = remaining == 0 and 1100 * dt or 0 -- burst
		delay = remaining == 0 and 1100 * dt or 1000 * dt / remaining -- smooth
		-- p(remaining, dt, delay)

	end

	setTimeout(delay, continue, self)

end

return RateLimiter
