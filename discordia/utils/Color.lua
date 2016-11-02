local bit = require('bit')

local round = math.round
local format = string.format
local lshift, rshift, band = bit.lshift, bit.rshift, bit.band

local Color, get, set = class('Color')

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
	self._value = value or 0

end

get('value', '_value')

get('r', function(self)
	return rshift(band(self._value, 0xFF0000), 16)
end)

get('g', function(self)
	return rshift(band(self._value, 0x00FF00), 8)
end)

get('b', function(self)
	return band(self._value, 0x0000FF)
end)

set('r', function(self, v)
	self._value = lshift(v, 16) + lshift(self.g, 8) + self.b
end)

set('g', function(self, v)
	self._value = lshift(self.r, 16) + lshift(v, 8) + self.b
end)

set('b', function(self, v)
	self._value = lshift(self.r, 16) + lshift(self.g, 8) + b
end)

function Color:__tostring()
	return format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:__eq(other)
	return self.__class == other.__class and self._value == other._value
end

function Color:__add(other)
	return Color(self._value + other._value)
end

function Color:__sub(other)
	return Color(self._value - other._value)
end

function Color:__mul(n)
	if type(self) == 'number' then self, n = n, self end
	return Color(self._value * n)
end

function Color:__div(n)
	return Color(self._value / n)
end

function Color:toHex()
	return format('0x%06X', self._value)
end

function Color:copy()
	return Color(self._value)
end

return Color
