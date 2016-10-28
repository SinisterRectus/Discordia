local hrtime = require('uv').hrtime

local Stopwatch = class('Stopwatch')

function Stopwatch:__init()
	self.time = hrtime()
end

function Stopwatch:getHours()
	return self:getSeconds() / 3600
end

function Stopwatch:getMinutes()
	return self:getSeconds() / 60
end

function Stopwatch:getSeconds()
	return self:getNanoseconds() * 1E-9
end

function Stopwatch:getMilliseconds()
	return self:getNanoseconds() * 1E-6
end

function Stopwatch:getMicroseconds()
	return self:getNanoseconds() * 1E-3
end

function Stopwatch:getNanoseconds()
	return hrtime() - self.time
end

Stopwatch.restart = Stopwatch.__init

return Stopwatch
