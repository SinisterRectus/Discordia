local BitArray = require('../libs/utils/BitArray')
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

	assertEqual(BitArray(v[2], 2):toBin(), v[2])
	assertEqual(BitArray(v[3], 8):toBin(), v[2])
	assertEqual(BitArray(v[4], 10):toBin(), v[2])
	assertEqual(BitArray(v[5], 16):toBin(), v[2])

	assertEqual(BitArray(v[2], 2):toOct(), v[3])
	assertEqual(BitArray(v[3], 8):toOct(), v[3])
	assertEqual(BitArray(v[4], 10):toOct(), v[3])
	assertEqual(BitArray(v[5], 16):toOct(), v[3])

	assertEqual(BitArray(v[2], 2):toDec(), v[4])
	assertEqual(BitArray(v[3], 8):toDec(), v[4])
	assertEqual(BitArray(v[4], 10):toDec(), v[4])
	assertEqual(BitArray(v[5], 16):toDec(), v[4])

	assertEqual(BitArray(v[2], 2):toHex(), v[5])
	assertEqual(BitArray(v[3], 8):toHex(), v[5])
	assertEqual(BitArray(v[4], 10):toHex(), v[5])
	assertEqual(BitArray(v[5], 16):toHex(), v[5])

	assertEqual(BitArray(v[2], 2):toString(16), v[5])
	assertEqual(BitArray(v[3], 8):toString(16), v[5])
	assertEqual(BitArray(v[4], 10):toString(16), v[5])
	assertEqual(BitArray(v[5], 16):toString(16), v[5])

end

do

	local b = BitArray()

	b:enableBit(5)
	assertTrue(b:hasBit(5))
	assertEqual(b:toBin(), '10000')
	assertEqual(b:toBin(8), '00010000')

	b:toggleBit(4)
	assertTrue(b:hasBit(4))
	assertEqual(b:toBin(), '11000')
	assertEqual(b:toBin(8), '00011000')

	b:toggleBit(4)
	assertFalse(b:hasBit(4))
	assertEqual(b:toBin(), '10000')
	assertEqual(b:toBin(8), '00010000')

	b:disableBit(5)
	assertFalse(b:hasBit(5))
	assertEqual(b:toBin(), '0')
	assertEqual(b:toBin(8), '00000000')

end

do

	local colors = {
		red = 1,
		green = 2,
		blue = 3,
	}

	local b = BitArray(colors)

	local t = b:toTable(colors)
	assertTrue(t.red)
	assertTrue(t.green)
	assertTrue(t.blue)

	b:disableBit(colors.blue)
	t = b:toTable(colors)
	assertTrue(t.red)
	assertTrue(t.green)
	assertFalse(t.blue)

end

local b1 = BitArray('0101', 2)
local b2 = BitArray('1001', 2)
assertEqual(b1:union(b2):toBin(4), '1101')
assertEqual(b1:intersection(b2):toBin(4), '0001')
assertEqual(b1:difference(b2):toBin(4), '0100')
assertEqual(b1:symmetricDifference(b2):toBin(4), '1100')

local b3 = BitArray()
for i = 1, 64 do
	b3:enableBit(i)
	assertTrue(b3:hasBit(i))
	b3:disableBit(i)
	assertFalse(b3:hasBit(i))
end

local b4 = BitArray {1, 2, 4}
assertTrue(b4:hasBit(1))
assertTrue(b4:hasBit(2))
assertTrue(b4:hasBit(4))
assertEqual(b4:toBin(), '1011')

assertTrue(BitArray(1) == BitArray(1))
assertTrue(BitArray(1) ~= BitArray(2))

for _, v in ipairs {
	{'1', 1, 'expected minimum 2, received 1'},
	{'1', 100, 'expected maximum 36, received 100'},
	{'1', {}, 'expected integer, received table'},
	{'-1', 10, 'expected minimum 0, received -1'},
	{'1.1', 10, 'expected integer, received 1.1'},
	{'-1.1', 10, 'expected integer, received -1.1'},
	{2^65, 10, 'expected maximum 1.844674407371e+19, received 3.6893488147419e+19'},
	{'a', 10, 'expected integer, received string'},
	{'b', 10, 'expected integer, received string'},
} do
	assertEqual(#v, 3)
	assertError(function() return BitArray(v[1], v[2]) end, v[3])
end

local b = BitArray()

assertError(function() return b:enableBit(0) end, 'expected minimum 1, received 0')
assertError(function() return b:enableBit(-1) end, 'expected minimum 1, received -1')
assertError(function() return b:toString(2, 0) end, 'expected minimum 1, received 0')
assertError(function() return b:toString(2, -1) end, 'expected minimum 1, received -1')
assertError(function() return b:toBin(0) end, 'expected minimum 1, received 0')
assertError(function() return b:toBin(-1) end, 'expected minimum 1, received -1')

assertError(function() return b:toString(2, {}) end, 'expected integer, received table')
assertError(function() return b:toString(2, {}) end, 'expected integer, received table')