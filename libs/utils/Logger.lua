local fs = require('fs')

local max = math.max
local date = os.date
local format = string.format
local stdout = process.stdout.handle
local openSync, writeSync = fs.openSync, fs.writeSync

-- local BLACK =   30
local RED =     31
local GREEN =   32
local YELLOW =  33
-- local BLUE =    34
-- local MAGENTA = 35
local CYAN =    36
-- local WHITE =   37

local config = {
	{RED, '[ERROR]'},
	{YELLOW, '[WARNING]'},
	{GREEN, '[INFO]'},
	{CYAN, '[DEBUG]'},
}

local function colorize(n, m, str)
	return format('\27[%i;%im%s\27[0m', n, m, str)
end

do -- parse config
	local n = 0
	for _, v in ipairs(config) do
		n = max(n, #v[2])
	end
	for _, v in pairs(config) do
		v[2] = format(format('%%-%is', n), v[2])
		v[3] = colorize(1, v[1], v[2])
	end
end

local Logger = require('class')('Logger')

function Logger:__init(level, dateTime, file)
	self._level = level
	self._dateTime = dateTime
	self._file = file and openSync(file, 'a')
end

--[[
@method log
@param level: number
@param msg: string
@param ...: *
@ret string
]]
function Logger:log(level, msg, ...)

	if self._level < level then return end

	local tag = config[level]
	if not tag then return end

	msg = format(msg, ...)

	local d = date(self._dateTime)
	if self._file then
		writeSync(self._file, -1, format('%s | %s | %s\n', d, tag[2], msg))
	end
	stdout:write(format('%s | %s | %s\n', d, tag[3], msg))

	return msg

end

return Logger
