local uv = require('uv')

local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep
local yield, resume, running = coroutine.yield, coroutine.resume, coroutine.running

local function onExit() end

local fmt = setmetatable({}, {
	__index = function(self, n)
		self[n] = '<' .. rep('i2', n)
		return self[n]
	end
})

local FFmpegProcess = require('class')('FFmpegProcess')

function FFmpegProcess:__init(path, rate, channels)

	self._stdout = uv.new_pipe(false)
	self._child = uv.spawn('ffmpeg', {
		args = {'-i', path, '-ar', rate, '-ac', channels, '-f', 's16le', 'pipe:1', '-loglevel', 'warning'},
		stdio = {0, self._stdout, 2},
	}, onExit)

	self._buffer = ''
	self:fill(0xFFFF, true)

end

function FFmpegProcess:fill(n, wait)

	-- if self._eof or #self._buffer >= n then return end

	wait = wait and running()

	self._stdout:read_start(function(err, chunk)
		if err or not chunk then
			self._eof = true
			self:close()
		elseif #chunk > 0 then
			self._buffer = self._buffer .. chunk
		end
		if self._eof or #self._buffer >= n then
			self._stdout:read_stop()
			if wait then
				return assert(resume(wait))
			end
		end
	end)

	if wait then
		yield()
	end

end


function FFmpegProcess:read(n)

	local bytes = n * 2

	if not self._eof then
		self:fill(bytes * 10, #self._buffer < bytes)
	end

	local buffer = self._buffer
	if #buffer >= bytes then
		self._buffer = buffer:sub(bytes + 1)
		local pcm = {unpack(fmt[n], buffer)}
		remove(pcm)
		return pcm
	end

end

function FFmpegProcess:close()
	self._child:kill()
	if not self._stdout:is_closing() then
		self._stdout:close()
	end
end

return FFmpegProcess
