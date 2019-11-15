local remove = table.remove
local unpack = string.unpack -- luacheck: ignore
local rep = string.rep

local fmt = setmetatable({}, {
	__index = function(self, n)
		self[n] = '<' .. rep('i2', n)
		return self[n]
	end
})

local PCMString = require('class')('PCMString')

function PCMString:__init(str)
	self._len = #str
	self._str = str
end

function PCMString:read(n)
	local i = self._i or 1
	if i + n * 2 < self._len then
		local pcm = {unpack(fmt[n], self._str, i)}
		self._i = remove(pcm)
		return pcm
	end
end

return PCMString
