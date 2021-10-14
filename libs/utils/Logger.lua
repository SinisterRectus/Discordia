local fs = require('fs')
local pp = require('pretty-print')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local date = os.date
local format, gsub, rep = string.format, string.gsub, string.rep
local stdout = pp.stdout
local openSync, writeSync, closeSync = fs.openSync, fs.writeSync, fs.closeSync
local checkEnum, checkType = typing.checkEnum, typing.checkType

local colors = {
	black   = 90,
	red     = 91,
	green   = 92,
	yellow  = 93,
	blue    = 94,
	magenta = 95,
	cyan    = 96,
	white   = 97,
}

local labels = {
	{'[CRITICAL]', colors.magenta},
	{'[ERROR]   ', colors.red},
	{'[WARNING] ', colors.yellow},
	{'[INFO]    ', colors.green},
	{'[DEBUG]   ', colors.cyan},
}

for _, v in ipairs(labels) do
	v[2] = format('\27[%i;%im%s\27[0m', 0, v[2], v[1])
end

local Logger = class('Logger')

function Logger:__init(level, dateFormat, filePath, useColors)
	self._level = checkEnum(enums.logLevel, level)
	self._dateFormat = dateFormat and checkType('string', dateFormat)
	self._file = filePath and openSync(filePath, 'a')
	self._useColors = not not useColors
	self._line = {nil, ' | ', nil, ' | ', nil, '\n'}
end

function Logger:setLevel(level)
	self._level = checkEnum(enums.logLevel, level)
end

function Logger:setDateTime(dateFormat)
	self._dateFormat = dateFormat and checkType('string', dateFormat) or nil
end

function Logger:setFile(path)
	if self._file then
		closeSync(self._file)
	end
	if path then
		self._file = assert(openSync(path, 'a'))
	end
end

function Logger:enableColors()
	self._useColors = true
end

function Logger:disableColors()
	self._useColors = false
end

function Logger:log(level, msg, ...)

	level = checkEnum(enums.logLevel, level)
	msg = checkType('string', msg)

	if self._level < level then return end
	local label = labels[level]

	local line = self._line
	line[1] = date(self._dateFormat)
	line[3] = label[1]
	line[5] = gsub(
		format(msg, ...),
		'\r?\n',
		'%0' .. rep(' ', #line[1] + 16 - 2) .. '| ' -- Timestamp + label (10) + separators (6)
	)

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
