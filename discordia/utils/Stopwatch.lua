local hrtime = require('uv').hrtime

local Stopwatch, property, method = class('Stopwatch')
Stopwatch.__description = "Utility that measures elapsed time with nanosecond precision."

function Stopwatch:__init()
	self._time = hrtime()
end

property('hours', function(self)
	return self.seconds / 3600
end, nil, 'number', "Elapsed time in hours")

property('minutes', function(self)
	return self.seconds / 60
end, nil, 'number', "Elapsed time in minutes")

property('seconds', function(self)
	return self.nanoseconds * 1E-9
end, nil, 'number', "Elapsed time in seconds")

property('milliseconds', function(self)
	return self.nanoseconds * 1E-6
end, nil, 'number', "Elapsed time in milliseconds")

property('microseconds', function(self)
	return self.nanoseconds * 1E-3
end, nil, 'number', "Elapsed time in microseconds")

property('nanoseconds', function(self)
	return hrtime() - self._time
end, nil, 'number', "Elapsed time in nanoseconds")

method('restart', Stopwatch.__init, nil, "Sets the stopwatch's time to zero.")

return Stopwatch
