local bit = require('bit')

local Color = class('Color')

function Color:__init(a, b, c)

	-- valid constructors:
	-- Color(114, 137, 218) -- RGB
	-- Color(7506394) -- decimal
	-- Color(0x7289DA) -- hexadecimal
	-- Color('7289DA') -- hex string
	-- Color('#7289DA') -- hex string
	-- Color('0x7289DA') -- hex string

	if a and b and c then
		self.r = math.round(math.clamp(a, 0, 255))
		self.g = math.round(math.clamp(b, 0, 255))
		self.b = math.round(math.clamp(c, 0, 255))
	elseif a then
		if type(a) == 'string' then
			a = tonumber(a:gsub('#', ''), 16)
		end
		a = math.round(math.clamp(a, 0, 0xFFFFFF))
		self.r = bit.rshift(bit.band(a, 0xFF0000), 16)
		self.g = bit.rshift(bit.band(a, 0x00FF00), 8)
		self.b = bit.band(a, 0x0000FF)
	end

end

function Color:__tostring()
	return string.format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:__eq(other)
	return self:isSameTypeAs(other) and self.value == other.value
end

function Color:__add(other)
	local r = math.clamp(self.r + other.r, 0, 255)
	local b = math.clamp(self.b + other.b, 0, 255)
	local g = math.clamp(self.g + other.g, 0, 255)
	return Color(r, g, b)
end

function Color:__sub(other)
	local r = math.clamp(self.r - other.r, 0, 255)
	local b = math.clamp(self.b - other.b, 0, 255)
	local g = math.clamp(self.g - other.g, 0, 255)
	return Color(r, g, b)
end

function Color:__mul(n)
	if type(self) == 'number' then self, n = n, self end
	local r = math.clamp(self.r * n, 0, 255)
	local b = math.clamp(self.b * n, 0, 255)
	local g = math.clamp(self.g * n, 0, 255)
	return Color(r, g, b)
end

function Color:__div(n)
	local r = math.clamp(self.r / n, 0, 255)
	local b = math.clamp(self.b / n, 0, 255)
	local g = math.clamp(self.g / n, 0, 255)
	return Color(r, b, g)
end

function Color:toHex()
	return string.format('0x%02X%02X%02X', self.r, self.g, self.b)
end

function Color:toDec()
	return 0x10000 * self.r + 0x100 * self.g + self.b
end

return Color
