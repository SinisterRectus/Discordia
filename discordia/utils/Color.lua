local bit = require('bit')

local round = math.round
local format = string.format
local lshift, rshift, band = bit.lshift, bit.rshift, bit.band

local Color = class('Color')

function Color:__init(a, b, c)

	-- valid constructors:
	-- Color(114, 137, 218) -- RGB
	-- Color(7506394) -- decimal
	-- Color(0x7289DA) -- hexadecimal
	-- Color('7289DA') -- hex string
	-- Color('#7289DA') -- hex string
	-- Color('0x7289DA') -- hex string

	local value
	if a and b and c then
		value = lshift(a, 16) + lshift(b, 8) + c
	elseif a then
		if type(a) == 'string' then
			value = tonumber(a:gsub('#', ''), 16)
		else
			value = tonumber(a)
		end
	end
	self.value = value or 0

end

function Color:__tostring()
	return format('Color: (%i, %i, %i)', self:toRGB())
end

function Color:__eq(other)
	return self.__class == other.__class and self.value == other.value
end

function Color:__add(other)
	return Color(self.value + other.value)
end

function Color:__sub(other)
	return Color(self.value - other.value)
end

function Color:__mul(n)
	if type(self) == 'number' then self, n = n, self end
	return Color(self.value * n)
end

function Color:__div(n)
	return Color(self.value / n)
end

function Color:toHex()
	return format('0x%06X', self.value)
end

function Color:toRGB()
	local v = self.value
	local r = rshift(band(v, 0xFF0000), 16)
	local g = rshift(band(v, 0x00FF00), 8)
	local b = band(v, 0x0000FF)
	return r, g, b
end

function Color:copy()
	return Color(self.value)
end

return Color
