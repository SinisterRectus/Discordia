local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep

local PCMString = require('class')('PCMString')

function PCMString:__init(str)
	self._i = 1
	self._len = #str
	self._str = str
end

function PCMString:read(n)

	local i = self._i
	local j = i + n * 2

	if j < self._len then
		local pcm = self._str:sub(i, j - 1)
		local fmt = rep('<i2', n)
		pcm = {unpack(fmt, pcm)}
		self._i = j
		remove(pcm)
		return pcm
	end

end

return PCMString
