local helpers = require('../helpers')
local class = require('../class')
local Emitter = require('./Emitter')

local UTC_FMT = '!*t'
local LOCAL_FMT = '*t'

local Clock = class('Clock', Emitter)

local clocks = {
	[UTC_FMT] = {},
	[LOCAL_FMT] = {},
}

local function isActive()
	for _, tbl in pairs(clocks) do
		if next(tbl) then
			return true
		end
	end
	return false
end

local function initialize()
	local times = {}
	for fmt in pairs(clocks) do
		times[fmt] = os.date(fmt)
	end
	return helpers.setInterval(1000, function()
		for fmt, tbl in pairs(clocks) do
			local old = times[fmt]
			local new = os.date(fmt)
			for k, v in pairs(new) do
				if v ~= old[k] then
					for clock in pairs(tbl) do
						clock:emit(k, new)
					end
				end
			end
			times[fmt] = new
		end
	end)
end

local timer = nil

function Clock:__init(utc)
	Emitter.__init(self)
	self._format = utc and UTC_FMT or LOCAL_FMT
end

function Clock:start()
	timer = timer or initialize()
	clocks[self._format][self] = true
end

function Clock:stop()
	clocks[self._format][self] = nil
	if timer and not isActive() then
		helpers.clearTimer(timer)
		timer = nil
	end
end

return Clock