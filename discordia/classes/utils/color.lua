local bit = require('bit')
local Color = class('Color')

function Color:__init(r, g, b)
	self.r = math.clamp(r, 0, 255)
	self.g = math.clamp(g, 0, 255)
	self.b = math.clamp(b, 0, 255)
end

function Color.fromHex(num)
	if type(num) == 'string' then
		num = tonumber(num:gsub('#', ''), 16)
	end
	return Color.fromDec(num)
end

function Color.fromDec(num)
	local r = bit.band(bit.rshift(num, 16), 0xFF)
	local g = bit.band(bit.rshift(num, 8), 0xFF)
	local b = bit.band(num, 0xFF)
	return Color(r, g, b)
end

function Color:__tostring()
	return string.format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:toHex()
	return string.format('#%02X%02X%02X', self.r, self.g, self.b)
end

function Color:toDec()
	return self.r + self.g * 256 + self.b * 65536
end

return Color
