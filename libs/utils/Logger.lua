local fs = require('fs')
local pp = require('pretty-print')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local date = os.date
local format = string.format
local stdout = pp.stdout
local openSync, writeSync = fs.openSync, fs.writeSync
local checkEnum = typing.checkEnum

local labels = {} do
	local n = 0
	for k in pairs(enums.logColor) do
		n = math.max(n, #k)
	end
	for k, v in pairs(enums.logColor) do
		local label = '[' .. k:upper() .. ']' .. string.rep(' ', n - #k)
		labels[enums.logLevel[k]] = {label, format('\27[%i;%im%s\27[0m', 1, v, label)}
	end
end

local Logger = class('Logger')

function Logger:__init(level, dateTime, filePath, useColors)
	self._level = level
	self._dateTime = dateTime
	self._file = filePath and openSync(filePath, 'a')
	self._useColors = useColors
	self._line = {nil, ' | ', nil, ' | ', nil, '\n'}
end

function Logger:log(level, msg, ...)

	level = checkEnum(enums.logLevel, level)
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
