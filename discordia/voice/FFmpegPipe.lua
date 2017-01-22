local spawn = require('coro-spawn')
local constants = require('./constants')

local wrap = coroutine.wrap
local remove = table.remove
local unpack, rep = string.unpack, string.rep

local FFMPEG = constants.FFMPEG

local FFmpegPipe = class('FFmpegPipe')

function FFmpegPipe:__init(filename, client)

	self._eof = false
	self._data = ''

	local child = spawn(FFMPEG, {
		args = {'-i', filename, '-ar', '48000', '-ac', '2', '-f', 's16le', 'pipe:1', '-loglevel', 'warning'},
	})

	wrap(function()
		local stderr = child.stderr
		for chunk in stderr.read do
			client:warning('[FFmpeg] ' .. chunk)
		end
		pcall(stderr.handle.close, stderr.handle)
	end)()

	local stdin = child.stdin
	local stdout = child.stdout

	self._read = stdout.read
	self._write = stdin.write
	self._handles = {child.handle, stdin.handle, stdout.handle}

end

function FFmpegPipe:read(size)

	local data = self._data
	local read = self._read

	while not self._eof and #data < size do
		local chunk = read()
		if chunk then
			data = data .. chunk
		else
			self._eof = true
		end
	end

	local chunk = data:sub(1, size)
	self._data = data:sub(size + 1)

	local len = #chunk
	if len > 0 then
		chunk = {unpack(rep('<H', len / 2), chunk)}
		remove(chunk) -- remove position value
		return chunk
	end

end

function FFmpegPipe:write(data)
	return self._write(data)
end

function FFmpegPipe:close()
	for _, handle in ipairs(self._handles) do
		pcall(handle.close, handle)
	end
end

return FFmpegPipe
