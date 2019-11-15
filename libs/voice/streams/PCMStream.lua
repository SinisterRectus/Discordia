local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep

local fmt = setmetatable({}, {
	__index = function(self, n)
		self[n] = '<' .. rep('i2', n)
		return self[n]
	end
})

local PCMStream = require('class')('PCMStream')

function PCMStream:__init(stream)
	self._stream = stream
end

function PCMStream:read(n)
  local m = n * 2
  local str = self._stream:read(m)
	if str and #str == m then
		local pcm = {unpack(fmt[n], str)}
		remove(pcm)
		return pcm
	end
end

return PCMStream
