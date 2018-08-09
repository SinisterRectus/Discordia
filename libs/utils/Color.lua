--[=[
@ic Color
@p value number
@d Wrapper for 24-bit colors packed as a decimal value. See the static constructors for more information.
]=]

local class = require('class')

local format = string.format
local min, max, abs, floor = math.min, math.max, math.abs, math.floor
local lshift, rshift = bit.lshift, bit.rshift
local band, bor = bit.band, bit.bor
local bnot = bit.bnot
local isInstance = class.isInstance

local Color, get = class('Color')

local function check(self, other)
	if not isInstance(self, Color) or not isInstance(other, Color) then
		return error('Cannot perform operation with non-Color object', 2)
	end
end

local function clamp(n, mn, mx)
	return min(max(n, mn), mx)
end

function Color:__init(value)
	value = tonumber(value)
	self._value = value and band(value, 0xFFFFFF) or 0
end

function Color:__tostring()
	return format('Color: %s (%i, %i, %i)', self:toHex(), self:toRGB())
end

function Color:__eq(other) check(self, other)
	return self._value == other._value
end

function Color:__add(other) check(self, other)
	local r = clamp(self.r + other.r, 0, 0xFF)
	local g = clamp(self.g + other.g, 0, 0xFF)
	local b = clamp(self.b + other.b, 0, 0xFF)
	return Color.fromRGB(r, g, b)
end

function Color:__sub(other) check(self, other)
	local r = clamp(self.r - other.r, 0, 0xFF)
	local g = clamp(self.g - other.g, 0, 0xFF)
	local b = clamp(self.b - other.b, 0, 0xFF)
	return Color.fromRGB(r, g, b)
end

function Color:__mul(other)
	if not isInstance(self, Color) then
		self, other = other, self
	end
	other = tonumber(other)
	if other then
		local r = clamp(self.r * other, 0, 0xFF)
		local g = clamp(self.g * other, 0, 0xFF)
		local b = clamp(self.b * other, 0, 0xFF)
		return Color.fromRGB(r, g, b)
	else
		return error('Cannot perform operation with non-numeric object')
	end
end

function Color:__div(other)
	if not isInstance(self, Color) then
		return error('Division with Color is not commutative')
	end
	other = tonumber(other)
	if other then
		local r = clamp(self.r / other, 0, 0xFF)
		local g = clamp(self.g / other, 0, 0xFF)
		local b = clamp(self.b / other, 0, 0xFF)
		return Color.fromRGB(r, g, b)
	else
		return error('Cannot perform operation with non-numeric object')
	end
end

--[=[
@sm fromHex
@p hex string
@r Color
@d Constructs a new Color object from a hexadecimal string. The string may or may
not be prefixed by `#`; all other characters are interpreted as a hex string.
]=]
function Color.fromHex(hex)
	return Color(tonumber(hex:match('#?(.*)'), 16))
end

--[=[
@sm fromRGB
@p r number
@p g number
@p b number
@r Color
@d Constructs a new Color object from RGB values. Values are allowed to overflow
though one component will not overflow to the next component.
]=]
function Color.fromRGB(r, g, b)
	r = band(lshift(r, 16), 0xFF0000)
	g = band(lshift(g, 8), 0x00FF00)
	b = band(b, 0x0000FF)
	return Color(bor(bor(r, g), b))
end

local function fromHue(h, c, m)
	local x = c * (1 - abs(h / 60 % 2 - 1))
	local r, g, b
	if 0 <= h and h < 60 then
		r, g, b = c, x, 0
	elseif 60 <= h and h < 120 then
		r, g, b = x, c, 0
	elseif 120 <= h and h < 180 then
		r, g, b = 0, c, x
	elseif 180 <= h and h < 240 then
		r, g, b = 0, x, c
	elseif 240 <= h and h < 300 then
		r, g, b = x, 0, c
	elseif 300 <= h and h < 360 then
		r, g, b = c, 0, x
	end
	r = (r + m) * 0xFF
	g = (g + m) * 0xFF
	b = (b + m) * 0xFF
	return r, g, b
end

local function toHue(r, g, b)
	r = r / 0xFF
	g = g / 0xFF
	b = b / 0xFF
	local mn = min(r, g, b)
	local mx = max(r, g, b)
	local d = mx - mn
	local h
	if d == 0 then
		h = 0
	elseif mx == r then
		h = (g - b) / d % 6
	elseif mx == g then
		h = (b - r) / d + 2
	elseif mx == b then
		h = (r - g) / d + 4
	end
	h = floor(h * 60 + 0.5)
	return h, d, mx, mn
end

--[=[
@sm fromHSV
@p h number
@p s number
@p v number
@r Color
@d Constructs a new Color object from HSV values. Hue is allowed to overflow
while saturation and value are clamped to [0, 1].
]=]
function Color.fromHSV(h, s, v)
	h = h % 360
	s = clamp(s, 0, 1)
	v = clamp(v, 0, 1)
	local c = v * s
	local m = v - c
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

--[=[
@sm fromHSL
@p h number
@p s number
@p l number
@r Color
@d Constructs a new Color object from HSL values. Hue is allowed to overflow
while saturation and lightness are clamped to [0, 1].
]=]
function Color.fromHSL(h, s, l)
	h = h % 360
	s = clamp(s, 0, 1)
	l = clamp(l, 0, 1)
	local c = (1 - abs(2 * l - 1)) * s
	local m = l - c * 0.5
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

--[=[
@m toHex
@r string
@d Returns a 6-digit hexadecimal string that represents the color value.
]=]
function Color:toHex()
	return format('#%06X', self._value)
end

--[=[
@m toRGB
@r number
@r number
@r number
@d Returns the red, green, and blue values that are packed into the color value.
]=]
function Color:toRGB()
	return self.r, self.g, self.b
end

--[=[
@m toHSV
@r number
@r number
@r number
@d Returns the hue, saturation, and value that represents the color value.
]=]
function Color:toHSV()
	local h, d, mx = toHue(self.r, self.g, self.b)
	local v = mx
	local s = mx == 0 and 0 or d / mx
	return h, s, v
end

--[=[
@m toHSL
@r number
@r number
@r number
@d Returns the hue, saturation, and lightness that represents the color value.
]=]
function Color:toHSL()
	local h, d, mx, mn = toHue(self.r, self.g, self.b)
	local l = (mx + mn) * 0.5
	local s = d == 0 and 0 or d / (1 - abs(2 * l - 1))
	return h, s, l
end

--[=[@p value number The raw decimal value that represents the color value.]=]
function get.value(self)
	return self._value
end

local function getByte(value, offset)
	return band(rshift(value, offset), 0xFF)
end

--[=[@p r number The value that represents the color's red-level.]=]
function get.r(self)
	return getByte(self._value, 16)
end

--[=[@p g number The value that represents the color's green-level.]=]
function get.g(self)
	return getByte(self._value, 8)
end

--[=[@p b number The value that represents the color's blue-level.]=]
function get.b(self)
	return getByte(self._value, 0)
end

local function setByte(value, offset, new)
	local byte = lshift(0xFF, offset)
	value = band(value, bnot(byte))
	return bor(value, band(lshift(new, offset), byte))
end

--[=[
@m setRed
@r nil
@d Sets the color's red-level.
]=]
function Color:setRed(r)
	self._value = setByte(self._value, 16, r)
end

--[=[
@m setGreen
@r nil
@d Sets the color's green-level.
]=]
function Color:setGreen(g)
	self._value = setByte(self._value, 8, g)
end

--[=[
@m setBlue
@r nil
@d Sets the color's blue-level.
]=]
function Color:setBlue(b)
	self._value = setByte(self._value, 0, b)
end

--[=[
@m toHSL
@r Color
@d Returns a new copy of the original color object.
]=]
function Color:copy()
	return Color(self._value)
end

return Color
