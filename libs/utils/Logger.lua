local fs = require('fs')
local pp = require('pretty-print')
local class = require('../class')

local date = os.date
local format = string.format
local stdout = pp.stdout
local openSync, writeSync = fs.openSync, fs.writeSync

local colors = {
	black   = 30,
	red     = 31,
	green   = 32,
	yellow  = 33,
	blue    = 34,
	magenta = 35,
	cyan    = 36,
	white   = 37,
}

local levels = {
	{'error',   '[ERROR]  ', colors.red},
	{'warning', '[WARNING]', colors.yellow},
	{'info',    '[INFO]   ', colors.green},
	{'debug',   '[DEBUG]  ', colors.cyan},
}

local Logger = class('Logger')

function Logger:__init(level, dateTime, filePath, useColors)
	self._level = level
	self._dateTime = dateTime
	self._file = filePath and openSync(filePath, 'a')
	self._useColors = useColors
	self._line = {nil, ' | ', nil, ' | ', nil, '\n'}
end

for i, v in ipairs(levels) do
	v[3] = ('\27[%i;%im%s\27[0m'):format(1, v[3], v[2])
	levels[v[1]] = i
	Logger[v[1]] = function(self, fmt, ...)
		return self:log(i, fmt, ...)
	end
end

function Logger:log(level, msg, ...)

	if type(level) == 'string' then
		level = levels[level] -- convert name to index
	end

	if type(level) == 'number' then
		if self._level < level then return end
		level = levels[level] -- convert index to table
	end

	if not level then return end

	local line = self._line
	line[1] = date(self._dateTime)
	line[3] = level[2]
	line[5] = format(msg, ...)

	if self._file then
		writeSync(self._file, -1, line)
	end

	if self._useColors then
		line[3] = level[3]
	end
	stdout:write(line)

	return line[5]

end

return Logger
