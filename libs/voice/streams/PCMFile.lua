local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep

local PCMFile = require('class')('PCMFile')

function PCMFile:__init(file)
	self._file = file
end

function PCMFile:read(n)
	local size = n * 2
	local pcm = self._file:read(size)
	if #pcm == size then
		local fmt = rep('<i2', n)
		pcm = {unpack(fmt, pcm)}
		remove(pcm)
		return pcm
	end
end

return PCMFile
