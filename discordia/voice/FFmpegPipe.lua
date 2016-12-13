local uv = require('uv')
local constants = require('./constants')

local spawn, new_pipe = uv.spawn, uv.new_pipe
local running, yield, resume = coroutine.running, coroutine.yield, coroutine.resume
local unpack, rep = string.unpack, string.rep

local FFMPEG = constants.FFMPEG

local FFmpegPipe = class('FFmpegPipe')

function FFmpegPipe:__init(filename, client)

	self._eof = false
	self._data = ''

	local stdin = new_pipe(false)
	local stdout = new_pipe(false)
	local stderr = new_pipe(false)

	self._handle = spawn(FFMPEG, {
		args = {'-i', filename, '-ar', '48000', '-ac', '2', '-f', 's16le', 'pipe:1', '-loglevel', 'warning'},
		stdio = {stdin, stdout, stderr}
	}, function() end)

	stderr:read_start(function(err, chunk)
		assert(not err, err)
		if chunk then return client:warning('[FFmpeg] ' .. chunk) end
	end)

	self._stdin = stdin
	self._stdout = stdout
	self._stderr = stderr

end

function FFmpegPipe:read(size)

	local eof = self._eof
	local data = self._data
	local stdout = self._stdout

	if not eof and #data < size then
		local thread = running()
		stdout:read_start(function(err, chunk)
			assert(not err, err)
			if chunk then
				data = data .. chunk
				if #data > size then
					stdout:read_stop()
					resume(thread)
				end
			else
				self._eof = true
				stdout:read_stop()
				resume(thread)
			end
		end)
		yield()
	end

	local chunk = data:sub(1, size)
	self._data = data:sub(size + 1)

	local len = #chunk
	return len > 0 and {unpack(rep('<H', len / 2), chunk)} or nil

end

function FFmpegPipe:write(data)
	self._stdin:write(data)
end

function FFmpegPipe:close()
	if not self._stdin:is_closing() then self._stdin:close() end
	if not self._stdout:is_closing() then self._stdout:close() end
	if not self._stderr:is_closing() then self._stderr:close() end
	if not self._handle:is_closing() then self._handle:close() end
end

return FFmpegPipe
