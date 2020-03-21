local Color = require('../libs/utils/Color')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertError = utils.assertError

for n = 0, 24 do
	n = 2 ^ n - 1
	local c = Color.fromDec(n)
	assertEqual(Color.fromDec(c:toDec()), c)
	assertEqual(Color.fromHex(c:toHex()), c)
	assertEqual(Color.fromRGB(c:toRGB()), c)
end

for n = 0, 359 do -- HSL and HSV are usually not-reversible
	assertEqual(Color.fromHSV(n, 1, 1):toHSV(), n)
	assertEqual(Color.fromHSL(n, 0.5, 0.5):toHSL(), n)
end

local blurple = {
	dec = 0x7289DA, hex = '7289DA',
	r = 114, g = 137, b = 218,
}

do
	local c = Color.fromDec(blurple.dec)
	assertEqual(c:toDec(), blurple.dec)
	assertEqual(c:toHex(), blurple.hex)
	local r, g, b = c:toRGB()
	assertEqual(r, blurple.r)
	assertEqual(g, blurple.g)
	assertEqual(b, blurple.b)
end

do
	local c = Color.fromHex(blurple.hex)
	assertEqual(c:toDec(), blurple.dec)
	assertEqual(c:toHex(), blurple.hex)
	local r, g, b = c:toRGB()
	assertEqual(r, blurple.r)
	assertEqual(g, blurple.g)
	assertEqual(b, blurple.b)
end

do
	local c = Color.fromRGB(blurple.r, blurple.g, blurple.b)
	assertEqual(c:toDec(), blurple.dec)
	assertEqual(c:toHex(), blurple.hex)
	local r, g, b = c:toRGB()
	assertEqual(r, blurple.r)
	assertEqual(g, blurple.g)
	assertEqual(b, blurple.b)
end

do
	local a = Color.fromRGB(1, 1, 1)
	local b = Color.fromRGB(255, 255, 255)
	assertEqual(a:lerp(b, 0.5), Color.fromRGB(128, 128, 128))
end

assertEqual(Color.fromRGB(-1, -1, -1), Color.fromRGB(0, 0, 0))
assertEqual(Color.fromRGB(1000, 1000, 1000), Color.fromRGB(255, 255, 255))

assertEqual(Color.fromRGB(1, 2, 3) + Color.fromRGB(4, 5, 6), Color.fromRGB(5, 7, 9))
assertEqual(Color.fromRGB(255, 255, 255) + Color.fromRGB(1, 2, 3), Color.fromRGB(255, 255, 255))

assertEqual(Color.fromRGB(4, 5, 6) - Color.fromRGB(1, 2, 3), Color.fromRGB(3, 3, 3))
assertEqual(Color.fromRGB(1, 2, 3) - Color.fromRGB(1, 2, 3), Color.fromRGB(0, 0, 0))
assertEqual(Color.fromRGB(0, 0, 0) - Color.fromRGB(1, 2, 3), Color.fromRGB(0, 0, 0))

assertEqual(Color.fromRGB(2, 4, 6) * 2, Color.fromRGB(4, 8, 12))
assertEqual(Color.fromRGB(1, 2, 3) * 100, Color.fromRGB(100, 200, 255))

assertEqual(Color.fromRGB(2, 4, 6) / 2, Color.fromRGB(1, 2, 3))
assertEqual(Color.fromRGB(1, 2, 3) / 100, Color.fromRGB(0, 0, 0))

assertError(function() return 1 / Color() end, 'division not commutative')
assertError(function() return Color() < {} end, 'cannot perform operation')
assertError(function() return Color() > {} end, 'cannot perform operation')
assertError(function() return Color() <= {} end, 'cannot perform operation')
assertError(function() return Color() >= {} end, 'cannot perform operation')
assertError(function() return Color() + {} end, 'cannot perform operation')
assertError(function() return Color() - {} end, 'cannot perform operation')
assertError(function() return Color() % {} end, 'cannot perform operation')
assertError(function() return Color() * {} end, 'cannot perform operation')
assertError(function() return Color() / {} end, 'cannot perform operation')
assertError(function() return Color() < 1 end, 'cannot perform operation')
assertError(function() return Color() > 1 end, 'cannot perform operation')
assertError(function() return Color() <= 1 end, 'cannot perform operation')
assertError(function() return Color() >= 1 end, 'cannot perform operation')
assertError(function() return Color() + 1 end, 'cannot perform operation')
assertError(function() return Color() - 1 end, 'cannot perform operation')
assertError(function() return Color() % 1 end, 'cannot perform operation')

assertError(function() return Color.fromRGB({}) end, 'expected number, received table')
assertError(function() return Color.fromDec({}) end, 'expected number, received table')
assertError(function() return Color.fromHex({}) end, 'expected number, received table')
assertError(function() return Color.fromHex('G') end, 'expected number, received string')
