local fs = require('fs')

local date = os.date
local format = string.format
local stdout = process.stdout.handle
local openSync, writeSync = fs.openSync, fs.writeSync

-- local BLACK   = 30
local RED     = 31
local GREEN   = 32
local YELLOW  = 33
-- local BLUE    = 34
-- local MAGENTA = 35
local CYAN    = 36
-- local WHITE   = 37

local config = {
	{'[ERROR]  ', RED},
	{'[WARNING]', YELLOW},
	{'[INFO]   ', GREEN},
	{'[DEBUG]  ', CYAN},
}

do -- parse config
	local bold = 1
	for _, v in ipairs(config) do
		v[2] = format('\27[%i;%im%s\27[0m', bold, v[2], v[1])
	end
end

local Logger = require('class')('Logger')

function Logger:__init(level, dateTime, file)
	self._level = level
	self._dateTime = dateTime
	self._file = file and openSync(file, 'a')
end

function Logger:log(level, msg, ...)

	if self._level < level then return end

	local tag = config[level]
	if not tag then return end

	msg = format(msg, ...)

	local d = date(self._dateTime)
	if self._file then
		writeSync(self._file, -1, format('%s | %s | %s\n', d, tag[1], msg))
	end
	stdout:write(format('%s | %s | %s\n', d, tag[2], msg))

	return msg

end

return Logger
