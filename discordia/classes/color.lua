local bit = require('bit')
local Color = class('Color')

function Color:__init(a, b, c)
	if a and b and c then
		self.r = math.round(math.clamp(a, 0, 255))
		self.g = math.round(math.clamp(b, 0, 255))
		self.b = math.round(math.clamp(c, 0, 255))
	elseif a then
		if type(a) == 'string' then
			a = tonumber(a:gsub('#', ''), 16)
		end
		a = math.round(math.clamp(a, 0, 16777215))
		self.r = bit.band(bit.rshift(a, 16), 0xFF)
		self.g = bit.band(bit.rshift(a, 8), 0xFF)
		self.b = bit.band(a, 0xFF)
	end
end

function Color:__tostring()
	return string.format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:__eq(other)
	return type(other) == 'table' and other.__name == 'Color' and self.r == other.r and self.b == other.b and self.g == other.g
end

function Color:__add(other)
	assert(type(other) == 'table' and other.__name == 'Color', 'Cannot add non-color object.')
	local r = math.clamp(self.r + other.r, 0, 255)
	local b = math.clamp(self.b + other.b, 0, 255)
	local g = math.clamp(self.g + other.g, 0, 255)
	return Color(r, b, g)
end

function Color:__sub(other)
	assert(type(other) == 'table' and other.__name == 'Color', 'Cannot subtract non-color object.')
	local r = math.clamp(self.r - other.r, 0, 255)
	local b = math.clamp(self.b - other.b, 0, 255)
	local g = math.clamp(self.g - other.g, 0, 255)
	return Color(r, b, g)
end

function Color.__mul(a, b)
	local color, n
	if type(a) == 'number' and type(b) == 'table' and b.__name == 'Color' then
		color, n = b, a
	elseif type(b) == 'number' and type(a) == 'table' and a.__name == 'Color' then
		color, n = a, b
	else
		error('Factor must be a valid number.')
	end
	local r = math.clamp(color.r * n, 0, 255)
	local b = math.clamp(color.b * n, 0, 255)
	local g = math.clamp(color.g * n, 0, 255)
	return Color(r, b, g)
end

function Color.__div(a, b)
	local color, n
	if type(a) == 'number' and type(b) == 'table' and b.__name == 'Color' then
		color, n = b, a
	elseif type(b) == 'number' and type(a) == 'table' and a.__name == 'Color' then
		color, n = a, b
	else
		error('Divisor must be a valid number.')
	end
	local r = math.clamp(color.r / n, 0, 255)
	local b = math.clamp(color.b / n, 0, 255)
	local g = math.clamp(color.g / n, 0, 255)
	return Color(r, b, g)
end

function Color:toHex()
	return string.format('0x%02X%02X%02X', self.r, self.g, self.b)
end

function Color:toDec()
	return 65536 * self.r + 256 * self.g + self.b
end

return Color
