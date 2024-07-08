local class = require('../class')
local typing = require('../typing')

local isInstance = class.isInstance
local checkNumber = typing.checkNumber
local min, max, abs, floor = math.min, math.max, math.abs, math.floor
local lshift, rshift, band, bor = bit.lshift, bit.rshift, bit.band, bit.bor
local format = string.format

local function clamp(n, mn, mx)
	return min(max(n, mn), mx)
end

local function lerp(a, b, t)
	return a + t * (b - a)
end

local function round(n)
	return floor(n + 0.5)
end

local function getByte(n, m)
	return band(rshift(n, m), 0xFF)
end

local function checkByte(n, m)
	return lshift(clamp(round(checkNumber(n)), 0, 0xFF), m)
end

local function checkValue(n, base)
	return clamp(round(checkNumber(n, base)), 0, 0xFFFFFF)
end

local function checkFloat(n)
	return clamp(checkNumber(n), 0, 1)
end

local function checkAngle(n)
	return round(checkNumber(n) % 360)
end

local function fromHue(h, c, m)
	local x = c * (1 - abs(h / 60 % 2 - 1))
	local r, g, b
	if h < 60 then
		r, g, b = c, x, 0
	elseif h < 120 then
		r, g, b = x, c, 0
	elseif h < 180 then
		r, g, b = 0, c, x
	elseif h < 240 then
		r, g, b = 0, x, c
	elseif h < 300 then
		r, g, b = x, 0, c
	elseif h < 360 then
		r, g, b = c, 0, x
	end
	return (r + m) * 0xFF, (g + m) * 0xFF, (b + m) * 0xFF
end

local function toHue(r, g, b)
	r = r / 0xFF
	g = g / 0xFF
	b = b / 0xFF
	local v = max(r, g, b)
	local c = v - min(r, g, b)
	local h
	if c == 0 then
		h = 0
	elseif v == r then
		h = (g - b) / c + 0
	elseif v == g then
		h = (b - r) / c + 2
	elseif v == b then
		h = (r - g) / c + 4
	end
	return checkAngle(h * 60), c, v
end

local Color, get = class('Color')

local function checkColor(obj)
	if isInstance(obj, Color) then
		return obj:toRGB()
	end
	return error('cannot perform operation', 2)
end

function Color:__init(n, base)
	self._n = n and checkValue(n, base) or 0
end

function Color.fromDec(dec)
	return Color(dec, 10)
end

function Color.fromHex(hex)
	return Color(hex, 16)
end

function Color.fromRGB(r, g, b)
	return Color(bor(checkByte(r, 16), checkByte(g, 8), checkByte(b, 0)))
end

function Color.fromHSV(h, s, v)
	h = checkAngle(h)
	s = checkFloat(s)
	v = checkFloat(v)
	local c = v * s
	local m = v - c
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

function Color.fromHSL(h, s, l)
	h = checkAngle(h)
	s = checkFloat(s)
	l = checkFloat(l)
	local c = (1 - abs(2 * l - 1)) * s
	local m = l - c * 0.5
	local r, g, b = fromHue(h, c, m)
	return Color.fromRGB(r, g, b)
end

function Color:__eq(other)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return r1 == r2 and g1 == g2 and b1 == b2
end

function Color:__lt(other)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return r1 < r2 and g1 < g2 and b1 < b2
end

function Color:__le(other)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return r1 <= r2 and g1 <= g2 and b1 <= b2
end

function Color:__add(other)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return Color.fromRGB(r1 + r2, g1 + g2, b1 + b2)
end

function Color:__sub(other)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return Color.fromRGB(r1 - r2, g1 - g2, b1 - b2)
end

function Color:__mul(other)
	if tonumber(other) then
		local r, g, b = checkColor(self)
		return Color.fromRGB(r * other, g * other, b * other)
	elseif tonumber(self) then
		local r, g, b = checkColor(other)
		return Color.fromRGB(r * self, g * self, b * self)
	else
		return error('cannot perform operation')
	end
end

function Color:__div(other)
	if tonumber(other) then
		local r, g, b = checkColor(self)
		return Color.fromRGB(r / other, g / other, b / other)
	elseif tonumber(self) then
		return error('division not commutative')
	else
		return error('cannot perform operation')
	end
end

function Color:lerp(other, t)
	t = checkFloat(t)
	local r1, g1, b1 = checkColor(self)
	local r2, g2, b2 = checkColor(other)
	return Color.fromRGB(lerp(r1, r2, t), lerp(g1, g2, t), lerp(b1, b2, t))
end

function Color:toString()
	return format('#%s (%i, %i, %i)', self:toHex(), self:toRGB())
end

function Color:toDec()
	return self._n
end

function Color:toHex()
	return format('%06X', self._n)
end

function Color:toRGB()
	return self.r, self.g, self.b
end

function Color:toHSV()
	local h, c, v = toHue(self:toRGB())
	local s = v == 0 and 0 or c / v
	return h, s, v
end

function Color:toHSL()
	local h, c, v = toHue(self:toRGB())
	local l = v - c * 0.5
	local s = (l == 0 or l == 1) and 0 or c / (1 - abs(2 * v - c - 1))
	return h, s, l
end

function Color:copy()
	return Color(self._n)
end

function get:r()
	return getByte(self._n, 16)
end

function get:g()
	return getByte(self._n, 8)
end

function get:b()
	return getByte(self._n, 0)
end

return Color