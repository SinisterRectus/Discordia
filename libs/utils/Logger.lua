local uv = require('uv')
local class = require('../class')
local enums = require('../enums')
local typing = require('../typing')

local date = os.date
local format = string.format
local insert, concat = table.insert, table.concat
local checkEnum, checkType = typing.checkEnum, typing.checkType

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
	{'[CRT]', colors.magenta},
	{'[ERR]', colors.red},
	{'[WRN]', colors.yellow},
	{'[INF]', colors.green},
	{'[DBG]', colors.cyan},
}

for _, v in ipairs(labels) do
	v[3] = format('\27[%i;%im%s\27[0m', 0, v[2], v[1])
end

local Logger = class('Logger')

function Logger:__init(level)
	self._level = checkEnum(enums.logLevel, level)
	self._stream = stdout
	self._useColors = true
end

function Logger:setLevel(level)
	self._level = checkEnum(enums.logLevel, level)
end

function Logger:setDateFormat(dateFormat)
	self._dateFormat = dateFormat and checkType('string', dateFormat) or nil
end

function Logger:setStream(stream)
	local t = type(stream)
	if t == 'table' or t == 'userdata' and type(stream.write) == 'function' then
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

	level = checkEnum(enums.logLevel, level)
	if self._level < level then return end

	msg = format(checkType('string', msg), ...)
	local label = labels[level]
	local buf = {date(self._dateFormat), SEP, label[1], SEP}

	local i, j = msg:find('\n')
	if i then
		local space1 = string.rep(' ', #buf[1])
		local space2 = string.rep(' ', #buf[3])
		local n = 1
		while i do
			insert(buf, msg:sub(n, i))
			insert(buf, space1)
			insert(buf, SEP)
			insert(buf, space2)
			insert(buf, SEP)
			n = j + 1
			i, j = msg:find('\n', n)
		end
		insert(buf, msg:sub(n))
	else
		insert(buf, msg)
	end

	insert(buf, '\n')

	if self._file then
		uv.fs_write(self._file, concat(buf))
	end

	if self._stream then
		if self._useColors then
			buf[3] = label[3]
		end
		self._stream:write(concat(buf))
	end

	return msg

end

return Logger