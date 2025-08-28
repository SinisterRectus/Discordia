local uv = require('uv')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local checkType = typing.checkType

local stdout
if uv.guess_handle(1) == 'tty' then
	stdout = uv.new_tty(1, false)
else
	stdout = uv.new_pipe(false)
	uv.pipe_open(stdout, 1)
end

local MODE = tonumber('666', 8)
local SEP = ' | '

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
	[enums.logLevel.critical] = {'[CRT]', colors.magenta},
	[enums.logLevel.error]    = {'[ERR]', colors.red},
	[enums.logLevel.warning]  = {'[WRN]', colors.yellow},
	[enums.logLevel.info]     = {'[INF]', colors.green},
	[enums.logLevel.debug]    = {'[DBG]', colors.cyan},
}

for _, v in ipairs(labels) do
	v[3] = string.format('\27[%i;%im%s\27[0m', 0, v[2], v[1])
end

local Logger = class('Logger')

function Logger:__init(level)
	self._level = enums.logLevel(level)
	self._stream = stdout
	self._useColors = true
end

function Logger:setLevel(level)
	self._level = enums.logLevel(level)
end

function Logger:setDateFormat(dateFormat)
	self._dateFormat = dateFormat and checkType('string', dateFormat) or nil
end

function Logger:setStream(stream)
	local t = type(stream)
	if (t == 'table' or t == 'userdata') and type(stream.write) == 'function' then
		self._stream = stream
	else
		self._stream = nil
	end
end

function Logger:setFile(path)
	if self._file then
		uv.fs_close(self._file)
	end
	if path then
		self._file = uv.fs_open(path, 'a', MODE)
	end
end

function Logger:enableColors()
	self._useColors = true
end

function Logger:disableColors()
	self._useColors = false
end

function Logger:log(level, msg, ...)

	level = enums.logLevel(level)
	if self._level < level then return end

	msg = checkType('string', msg)
	if select('#', ...) > 0 then
		msg = string.format(msg, ...)
	end

	local label = labels[level]
	local buf = {os.date(self._dateFormat), SEP, label[1], SEP}

	local i, j = msg:find('\n')
	if i then
		local space1 = string.rep(' ', #buf[1])
		local space2 = string.rep(' ', #buf[3])
		local n = 1
		while i do
			table.insert(buf, msg:sub(n, i))
			table.insert(buf, space1)
			table.insert(buf, SEP)
			table.insert(buf, space2)
			table.insert(buf, SEP)
			n = j + 1
			i, j = msg:find('\n', n)
		end
		table.insert(buf, msg:sub(n))
	else
		table.insert(buf, msg)
	end

	table.insert(buf, '\n')

	if self._file then
		uv.fs_write(self._file, table.concat(buf))
	end

	if self._stream then
		if self._useColors then
			buf[3] = label[3]
		end
		self._stream:write(table.concat(buf))
	end

	return msg

end

return Logger