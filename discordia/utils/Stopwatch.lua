local hrtime = require('uv').hrtime

local Stopwatch, get = class('Stopwatch')

function Stopwatch:__init()
	self._time = hrtime()
end

get('hours', function(self)
	return self.seconds / 3600
end, 'number')

get('minutes', function(self)
	return self.seconds / 60
end, 'number')

get('seconds', function(self)
	return self.nanoseconds * 1E-9
end, 'number')

get('milliseconds', function(self)
	return self.nanoseconds * 1E-6
end, 'number')

get('microseconds', function(self)
	return self.nanoseconds * 1E-3
end, 'number')

get('nanoseconds', function(self)
	return hrtime() - self._time
end, 'number')

Stopwatch.restart = Stopwatch.__init

return Stopwatch
