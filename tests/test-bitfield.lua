local Bitfield = require('../libs/utils/Bitfield')
local utils = require('./utils')

local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertFalse = utils.assertFalse
local assertError = utils.assertError

local b = Bitfield()

assertEqual(b:toString(2), '0')
assertEqual(b:toString(8), '0')
assertEqual(b:toString(10), '0')
assertEqual(b:toString(16), '0')

assertEqual(b:toString(2, 2), '00')
assertEqual(b:toString(8, 2), '00')
assertEqual(b:toString(10, 2), '00')
assertEqual(b:toString(16, 2), '00')

assertEqual(b:toBin(1), '0')
assertEqual(b:toBin(2), '00')
assertEqual(b:toBin(3), '000')

assertEqual(Bitfield(15):toHex(), 'F')
assertEqual(Bitfield('F', 16):toHex(), 'F')
assertEqual(Bitfield(15):toHex(8), '0000000F')
assertEqual(Bitfield('F', 16):toHex(8), '0000000F')

assertEqual(Bitfield(15):toBin(), '1111')
assertEqual(Bitfield('F', 16):toBin(), '1111')
assertEqual(Bitfield(15):toBin(8), '00001111')
assertEqual(Bitfield('F', 16):toBin(8), '00001111')

assertEqual(Bitfield(15):toOct(), '17')
assertEqual(Bitfield('F', 16):toOct(), '17')
assertEqual(Bitfield(15):toOct(8), '00000017')
assertEqual(Bitfield('F', 16):toOct(8), '00000017')

assertEqual(Bitfield(15):toDec(), '15')
assertEqual(Bitfield('F', 16):toDec(), '15')
assertEqual(Bitfield(15):toDec(8), '00000015')
assertEqual(Bitfield('F', 16):toDec(8), '00000015')

assertEqual(Bitfield(15):toString(16), 'F')
assertEqual(Bitfield('F', 16):toString(16), 'F')
assertEqual(Bitfield(15):toString(16, 8), '0000000F')
assertEqual(Bitfield('F', 16):toString(16, 8), '0000000F')

b:enableBit(5)
assertTrue(b:hasBit(5))
assertTrue(b:hasValue(16))
assertEqual(b:toBin(), '10000')

b:toggleBit(4)
assertTrue(b:hasBit(4))
assertTrue(b:hasValue(8))
assertEqual(b:toBin(), '11000')

b:toggleBit(4)
assertFalse(b:hasBit(4))
assertFalse(b:hasValue(8))
assertEqual(b:toBin(), '10000')

b:disableBit(5)
assertFalse(b:hasBit(5))
assertFalse(b:hasValue(16))
assertEqual(b:toBin(), '0')

b:enableValue(8)
assertTrue(b:hasBit(4))
assertTrue(b:hasValue(8))
assertEqual(b:toBin(), '1000')

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

local b1 = Bitfield('0101', 2)
local b2 = Bitfield('1001', 2)
assertEqual(b1:union(b2):toBin(4), '1101')
assertEqual(b1:complement(b2):toBin(4), '0100')
assertEqual(b1:difference(b2):toBin(4), '1100')
assertEqual(b1:intersection(b2):toBin(4), '0001')

local b3 = Bitfield()
for i = 1, 31 do
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
	{2^31, 10, 'expected maximum 2147483647, received ' .. 2^31},
	{2^32, 10, 'expected maximum 2147483647, received ' .. 2^32},
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
assertError(function() return b:enableBit(32) end, 'expected maximum 31, received 32')
assertError(function() return b:enableBit(33) end, 'expected maximum 31, received 33')
assertError(function() return b:enableBit(64) end, 'expected maximum 31, received 64')
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
