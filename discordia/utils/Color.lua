local bit = require('bit')

local format = string.format
local rol, ror = bit.rol, bit.ror
local lshift, rshift, band = bit.lshift, bit.rshift, bit.band

local Color, property, method = class('Color')
Color.__description = "Wrapper for a color's decimal value. Constructor accepts a decimal number, hex number, hex string, or RGB values."

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

function Color:__tostring()
	return format('Color: (%i, %i, %i)', self.r, self.g, self.b)
end

function Color:__eq(other)
	return self.__name == other.__name and self._value == other._value
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

local function getByte(self, byte)
	return band(rshift(self._value, 8 * byte), 0xFF)
end

local function setByte(self, byte, v)
	local bits = 8 * byte  
	self._value = rol(lshift(rshift(ror(self._value, bits), 8), 8) + v, bits)
end

local function getR(self)
	return getByte(self, 2)
end

local function getG(self)
	return getByte(self, 1)
end

local function getB(self)
	return getByte(self, 0)
end

local function setR(self, r)
	setByte(self, 2, r)
end

local function setG(self, g)
	setByte(self, 1, g)
end

local function setB(self, b)
	setByte(self, 0, b)
end

local function toHex(self)
	return format('#%06X', self._value)
end

local function copy(self)
	return Color(self._value)
end

property('value', '_value', nil, 'number', "Decimal value representing the total color")
property('r', getR, setR, 'number', "Red level (0-255)")
property('g', getG, setG, 'number', "Green level (0-255)")
property('b', getB, setB, 'number', "Blue level (0-255)")

method('toHex', toHex, nil, "Returns a hex string for the color's value.")
method('copy', copy, nil, "Returns a new Color instance that is a copy of the original.")

return Color
