local PCMGenerator = require('class')('PCMGenerator')

function PCMGenerator:__init(fn)
		self._fn = fn
end

function PCMGenerator:read(n)
	local pcm = {}
	for i = 1, n, 2 do
		pcm[i], pcm[i + 1] = self._fn()
	end
	return pcm
end

return PCMGenerator
