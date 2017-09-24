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

function Color.fromHex(hex)
	return Color(tonumber(hex:match('#?(.*)'), 16))
end

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

function Color.fromHSV(h, s, v)
	h = h % 360
	s = clamp(s, 0, 1)
	v = clamp(v, 0, 1)
	local c = v * s
	local m = v - c
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

function Color.fromHSL(h, s, l)
	h = h % 360
	s = clamp(s, 0, 1)
	l = clamp(l, 0, 1)
	local c = (1 - abs(2 * l - 1)) * s
	local m = l - c * 0.5
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

function Color:toHex()
	return format('#%06X', self._value)
end

function Color:toRGB()
	return self.r, self.g, self.b
end

function Color:toHSV()
	local h, d, mx = toHue(self.r, self.g, self.b)
	local v = mx
	local s = mx == 0 and 0 or d / mx
	return h, s, v
end

function Color:toHSL()
	local h, d, mx, mn = toHue(self.r, self.g, self.b)
	local l = (mx + mn) * 0.5
	local s = d == 0 and 0 or d / (1 - abs(2 * l - 1))
	return h, s, l
end

function get.value(self)
	return self._value
end

local function getByte(value, offset)
	return band(rshift(value, offset), 0xFF)
end

function get.r(self)
	return getByte(self._value, 16)
end

function get.g(self)
	return getByte(self._value, 8)
end

function get.b(self)
	return getByte(self._value, 0)
end

local function setByte(value, offset, new)
	local byte = lshift(0xFF, offset)
	value = band(value, bnot(byte))
	return bor(value, band(lshift(new, offset), byte))
end

function Color:setRed(r)
	self._value = setByte(self._value, 16, r)
end

function Color:setGreen(g)
	self._value = setByte(self._value, 8, g)
end

function Color:setBlue(b)
	self._value = setByte(self._value, 0, b)
end

function Color:copy()
	return Color(self._value)
end

return Color
