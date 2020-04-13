local fs = require('fs')
local pp = require('pretty-print')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local date = os.date
local format = string.format
local stdout = pp.stdout
local openSync, writeSync = fs.openSync, fs.writeSync
local checkEnum, checkType = typing.checkEnum, typing.checkType

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

local labels = {
	{'[CRITICAL]', colors.magenta},
	{'[ERROR]   ', colors.red},
	{'[WARNING] ', colors.yellow},
	{'[INFO]    ', colors.green},
	{'[DEBUG]   ', colors.cyan},
}

for _, v in ipairs(labels) do
	v[2] = format('\27[%i;%im%s\27[0m', 1, v[2], v[1])
end

local Logger = class('Logger')

function Logger:__init(level, dateTime, filePath, useColors)
	self._level = checkEnum(enums.logLevel, level)
	self._dateTime = dateTime and checkType('string', dateTime)
	self._file = filePath and openSync(filePath, 'a')
	self._useColors = not not useColors
	self._line = {nil, ' | ', nil, ' | ', nil, '\n'}
end

function Logger:log(level, msg, ...)

	level = checkEnum(enums.logLevel, level)
	msg = checkType('string', msg)

	if self._level < level then return end
	local label = labels[level]

	local line = self._line
	line[1] = date(self._dateTime)
	line[3] = label[1]
	line[5] = format(msg, ...)

	if self._file then
		writeSync(self._file, -1, line)
	end

	if self._useColors then
		line[3] = label[2]
	end
	stdout:write(line)

	return line[5]

end

return Logger
