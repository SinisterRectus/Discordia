local bit = require('bit')
local Color = class('Color')

function Color:__init(a, b, c)
	if a and b and c then
		self.r = math.clamp(a, 0, 255)
		self.g = math.clamp(b, 0, 255)
		self.b = math.clamp(c, 0, 255)
	elseif a then
		if type(a) == 'string' then
			a = tonumber(a:gsub('#', ''), 16)
		end
		self.r = bit.band(bit.rshift(a, 16), 0xFF)
		self.g = bit.band(bit.rshift(a, 8), 0xFF)
		self.b = bit.band(a, 0xFF)
	end
end

function Color:__tostring()
	return string.format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:toHex()
	return string.format('%02X%02X%02X', self.r, self.g, self.b)
end

function Color:toDec()
	return 65536 * self.r + 256 * self.g + self.b
end

return Color
