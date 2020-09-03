local Bitfield = require('../libs/utils/Bitfield')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertFalse = utils.assertFalse
local assertError = utils.assertError

for _, v in ipairs {
	{0, '0','0', '0', '0',},
	{2^4 - 1, '1111', '17', '15', 'F'},
	{2^8 - 1, '11111111', '377', '255', 'FF'},
	{2^16 - 1, '1111111111111111', '177777', '65535', 'FFFF'},
	{2^31 - 1, '1111111111111111111111111111111', '17777777777', '2147483647', '7FFFFFFF'},
	{2^32 - 1, '11111111111111111111111111111111', '37777777777', '4294967295', 'FFFFFFFF'},
	{2^64 - 1, string.rep('1', 64), '1777777777777777777777', '18446744073709551615', 'FFFFFFFFFFFFFFFF'},
} do

	assertEqual(Bitfield(v[2], 2):toBin(), v[2])
	assertEqual(Bitfield(v[3], 8):toBin(), v[2])
	assertEqual(Bitfield(v[4], 10):toBin(), v[2])
	assertEqual(Bitfield(v[5], 16):toBin(), v[2])

	assertEqual(Bitfield(v[2], 2):toOct(), v[3])
	assertEqual(Bitfield(v[3], 8):toOct(), v[3])
	assertEqual(Bitfield(v[4], 10):toOct(), v[3])
	assertEqual(Bitfield(v[5], 16):toOct(), v[3])

	assertEqual(Bitfield(v[2], 2):toDec(), v[4])
	assertEqual(Bitfield(v[3], 8):toDec(), v[4])
	assertEqual(Bitfield(v[4], 10):toDec(), v[4])
	assertEqual(Bitfield(v[5], 16):toDec(), v[4])

	assertEqual(Bitfield(v[2], 2):toHex(), v[5])
	assertEqual(Bitfield(v[3], 8):toHex(), v[5])
	assertEqual(Bitfield(v[4], 10):toHex(), v[5])
	assertEqual(Bitfield(v[5], 16):toHex(), v[5])

	assertEqual(Bitfield(v[2], 2):toString(16), v[5])
	assertEqual(Bitfield(v[3], 8):toString(16), v[5])
	assertEqual(Bitfield(v[4], 10):toString(16), v[5])
	assertEqual(Bitfield(v[5], 16):toString(16), v[5])

end

local b = Bitfield()

b:enableBit(5)
assertTrue(b:hasBit(5))
assertTrue(b:hasValue(16))
assertEqual(b:toBin(), '10000')
assertEqual(b:toBin(8), '00010000')

b:toggleBit(4)
assertTrue(b:hasBit(4))
assertTrue(b:hasValue(8))
assertEqual(b:toBin(), '11000')
assertEqual(b:toBin(8), '00011000')

b:toggleBit(4)
assertFalse(b:hasBit(4))
assertFalse(b:hasValue(8))
assertEqual(b:toBin(), '10000')
assertEqual(b:toBin(8), '00010000')

b:disableBit(5)
assertFalse(b:hasBit(5))
assertFalse(b:hasValue(16))
assertEqual(b:toBin(), '0')
assertEqual(b:toBin(8), '00000000')

b:enableValue(8)
assertTrue(b:hasBit(4))
assertTrue(b:hasValue(8))
assertEqual(b:toBin(), '1000')
assertEqual(b:toBin(8), '00001000')

b:enableValue(7)
assertTrue(b:hasBit(4))
assertEqual(b:toBin(), '1111')
assertEqual(b:toHex(), 'F')

b:toggleValue(7)
assertTrue(b:hasBit(4))
assertTrue(b:hasValue(8))
assertFalse(b:hasValue(7))
assertFalse(b:hasValue(15))
assertEqual(b:toBin(), '1000')

local b0 = Bitfield()

local filter = {
	red = 1,
	green = 2,
	blue = 3,
}

b0:enableValue(filter.green)
assertEqual(b0:toArray(filter)[1], "green")
assertFalse(b0:toTable(filter).red)
assertTrue(b0:toTable(filter).green)
assertFalse(b0:toTable(filter).blue)
b0:disableValue(filter.green)

local b1 = Bitfield('0101', 2)
local b2 = Bitfield('1001', 2)
assertEqual(b1:union(b2):toBin(4), '1101')
assertEqual(b1:complement(b2):toBin(4), '0100')
assertEqual(b1:difference(b2):toBin(4), '1100')
assertEqual(b1:intersection(b2):toBin(4), '0001')

local b3 = Bitfield()
for i = 1, 64 do
	b3:enableBit(i)
	assertTrue(b3:hasBit(i))
	b3:disableBit(i)
	assertFalse(b3:hasBit(i))
end

assertTrue(Bitfield(1) == Bitfield(1))
assertTrue(Bitfield(1) ~= Bitfield(2))
assertTrue(Bitfield(1) < Bitfield(2))
assertTrue(Bitfield(2) > Bitfield(1))
assertTrue(Bitfield(1) <= Bitfield(1))
assertTrue(Bitfield(1) >= Bitfield(1))
assertTrue(Bitfield(1) <= Bitfield(2))
assertTrue(Bitfield(2) >= Bitfield(1))
assertTrue(Bitfield(1) == Bitfield(1))
assertEqual(Bitfield(1) + Bitfield(2), Bitfield(3))
assertEqual(Bitfield(2) + Bitfield(1), Bitfield(3))
assertEqual(Bitfield(2) - Bitfield(1), Bitfield(1))
assertEqual(Bitfield(12) % Bitfield(3), Bitfield(0))
assertEqual(Bitfield(12) % Bitfield(5), Bitfield(2))

assertError(function() return b:union(1) end, 'cannot perform operation')
assertError(function() return b:complement(1) end, 'cannot perform operation')
assertError(function() return b:difference(1) end, 'cannot perform operation')
assertError(function() return b:intersection(1) end, 'cannot perform operation')

for _, v in ipairs {
	{1, 1, 'expected minimum 2, received 1'},
	{1, 100, 'expected maximum 36, received 100'},
	{1, {}, 'expected integer, received table'},
	{-1, 10, 'expected minimum 0, received -1'},
	{1.1, 10, 'expected integer, received 1.1'},
	{-1.1, 10, 'expected integer, received -1.1'},
	{2^65, 10, 'expected maximum 1.844674407371e+19, received 3.6893488147419e+19'},
	{{}, 10, 'expected integer, received table'},
	{'a', 10, 'expected integer, received string'},
	{'b', 10, 'expected integer, received string'},
} do
	assertEqual(#v, 3)
	assertError(function() return Bitfield(v[1], v[2]) end, v[3])
	assertError(function() return b:enableValue(v[1], v[2]) end, v[3])
	assertError(function() return b:toggleValue(v[1], v[2]) end, v[3])
	assertError(function() return b:disableValue(v[1], v[2]) end, v[3])
end

assertError(function() return b:enableBit(0) end, 'expected minimum 1, received 0')
assertError(function() return b:enableBit(65) end, 'expected maximum 64, received 65')
assertError(function() return b:enableBit(-1) end, 'expected minimum 1, received -1')

assertError(function() return b:toString(2, 0) end, 'expected minimum 1, received 0')
assertError(function() return b:toString(2, -1) end, 'expected minimum 1, received -1')
assertError(function() return b:toBin(0) end, 'expected minimum 1, received 0')
assertError(function() return b:toBin(-1) end, 'expected minimum 1, received -1')

assertError(function() return b:toString(2, {}) end, 'expected integer, received table')
assertError(function() return b:toString(2, {}) end, 'expected integer, received table')

assertError(function() return 2 / Bitfield(2) end, 'division not commutative')
assertError(function() return Bitfield(2) < {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) > {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) <= {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) >= {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) + {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) - {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) % {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) * {} end, 'cannot perform operation')
assertError(function() return Bitfield(2) / {} end, 'cannot perform operation')
