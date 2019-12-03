--[=[
@c Logger
@t ui
@mt mem
@p level number
@p dateTime string
@op file string
@d Used to log formatted messages to stdout (the console) or to a file.
The `dateTime` argument should be a format string that is accepted by `os.date`.
The file argument should be a relative or absolute file path or `nil` if no log
file is desired. See the `logLevel` enumeration for acceptable log level values.
]=]

local fs = require('fs')

local date = os.date
local format = string.format
local stdout = _G.process.stdout.handle
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

--[=[
@m log
@p level number
@p msg string
@p ... *
@r string
@d If the provided level is less than or equal to the log level set on
initialization, this logs a message to stdout as defined by Luvit's `process`
module and to a file if one was provided on initialization. The `msg, ...` pair
is formatted according to `string.format` and returned if the message is logged.
]=]
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
