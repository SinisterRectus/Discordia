local BigInt = require('../libs/utils/BigInt')
local Stopwatch = require('../libs/utils/Stopwatch')
local utils = require('./utils')

local f = string.format
local assertEqual = utils.assertEqual
local assertTrue = utils.assertTrue
local assertFalse = utils.assertFalse
local assertError = utils.assertError

local sw = Stopwatch()

for _, STORAGE_BASE in ipairs {2, 10, 36, 2^4, 2^8, 2^16} do BigInt._debug(STORAGE_BASE)

assertEqual(BigInt('  +0b010  '):toString(2), '10')
assertEqual(BigInt('  -0x010  '):toString(16), '-10')

assertEqual(BigInt('0b10'), BigInt(2))
assertEqual(BigInt('0o10'), BigInt(8))
assertEqual(BigInt('0x10'), BigInt(16))

assertEqual(BigInt('0B10'), BigInt(2))
assertEqual(BigInt('0O10'), BigInt(8))
assertEqual(BigInt('0X10'), BigInt(16))

assertEqual(BigInt('10', 2), BigInt(2))
assertEqual(BigInt('10', 8), BigInt(8))
assertEqual(BigInt('10', 16), BigInt(16))

for base = 2, 36 do
	local a = BigInt('  +010  ', base)
	local b = BigInt('  -010  ', base)
	assertEqual(a:toString(base), '10')
	assertEqual(b:toString(base), '-10')
end

assertEqual(BigInt(' 0'):toString(), '0')
assertEqual(BigInt('+0'):toString(), '0')
assertEqual(BigInt('-0'):toString(), '0')

for i = 1, 100 do
	local oct = f('%o', i)
	local dec = f('%i', i)
	local hex = f('%X', i)
	assertEqual(BigInt(i):toNumber(), i)
	assertEqual(BigInt(-i):toNumber(), -i)
	assertEqual(BigInt(oct, 8):toString(8), oct)
	assertEqual(BigInt(dec, 10):toString(10), dec)
	assertEqual(BigInt(hex, 16):toString(16), hex)
	assertEqual(BigInt('-' .. oct, 8):toString(8), '-' .. oct)
	assertEqual(BigInt('-' .. dec, 10):toString(10), '-' .. dec)
	assertEqual(BigInt('-' .. hex, 16):toString(16), '-' .. hex)
end

local one = BigInt(1)
local two = BigInt(2)

assertTrue(one == one)
assertTrue(two == two)
assertTrue(one ~= two)
assertTrue(two ~= one)
assertTrue(one < two)
assertTrue(two > one)
assertTrue(one <= one)
assertTrue(two <= two)
assertTrue(one <= two)
assertTrue(two >= one)

assertFalse(one == two)
assertFalse(two == one)
assertFalse(one ~= one)
assertFalse(two ~= two)
assertFalse(one < one)
assertFalse(two < two)
assertFalse(two < one)
assertFalse(one > two)
assertFalse(two <= one)
assertFalse(one >= two)

for n = -10, 10 do
	local a = BigInt(n)
	assertEqual(a:copy(), a)
	assertEqual(-a, BigInt(-n))
	assertEqual(a:__bnot(), BigInt(bit.bnot(n)))
	for m = -10, 10 do
		local b = BigInt(m)
		assertEqual(a + b, BigInt(n + m))
		assertEqual(a * b, BigInt(n * m))
		assertEqual(a - b, BigInt(n - m))
		assertEqual(a:__band(b), BigInt(bit.band(n, m)))
		assertEqual(a:__bor(b), BigInt(bit.bor(n, m)))
		assertEqual(a:__bxor(b), BigInt(bit.bxor(n, m)))
		if m ~= 0 then
			assertEqual(a / b, BigInt(n / m))
			assertEqual(a % b, BigInt(n % m))
		end
		if m >= 0 then
			assertEqual(a ^ b, BigInt(n ^ m))
			assertEqual(a:__shl(b), BigInt(bit.lshift(n, m)))
			assertEqual(a:__shr(b), BigInt(bit.arshift(n, m)))
		end
	end
end

local a = string.rep('0', 128)
local b = string.rep('1', 128)
assertEqual(BigInt(a .. b, 2) + BigInt(b .. a, 2), BigInt(b .. b, 2))

assertEqual(one, BigInt(1.2))
assertEqual(one, BigInt(1.5))
assertEqual(one, BigInt(1.9))
-- assertEqual(-two, BigInt(-1.2))
-- assertEqual(-two, BigInt(-1.5))
-- assertEqual(-two, BigInt(-1.9))

assertEqual(BigInt('0b10'), BigInt('10', 2))
assertEqual(BigInt('0o10'), BigInt('10', 8))
assertEqual(BigInt('0x10'), BigInt('10', 16))
assertEqual(BigInt('0B10'), BigInt('10', 2))
assertEqual(BigInt('0O10'), BigInt('10', 8))
assertEqual(BigInt('0X10'), BigInt('10', 16))

assertEqual(BigInt('-0b10'), BigInt('-10', 2))
assertEqual(BigInt('-0o10'), BigInt('-10', 8))
assertEqual(BigInt('-0x10'), BigInt('-10', 16))
assertEqual(BigInt('-0B10'), BigInt('-10', 2))
assertEqual(BigInt('-0O10'), BigInt('-10', 8))
assertEqual(BigInt('-0X10'), BigInt('-10', 16))

assertError(function() BigInt('0+') end, 'invalid number format: 0+')
assertError(function() BigInt('0-') end, 'invalid number format: 0-')
assertError(function() BigInt('+ 0') end, 'invalid number format: + 0')
assertError(function() BigInt('++0') end, 'invalid number format: ++0')
assertError(function() BigInt('- 0') end, 'invalid number format: - 0')
assertError(function() BigInt('--0') end, 'invalid number format: --0')
assertError(function() BigInt('1 2') end, 'invalid number format: 1 2')
assertError(function() BigInt('00b0', 2) end, 'invalid number format: 00b0')
assertError(function() BigInt('00o0', 8) end, 'invalid number format: 00o0')
assertError(function() BigInt('00x0', 16) end, 'invalid number format: 00x0')
assertError(function() BigInt('0b10', 10) end, 'invalid number format: 0b10')
assertError(function() BigInt('0o10', 10) end, 'invalid number format: 0o10')
assertError(function() BigInt('0x10', 10) end, 'invalid number format: 0x10')
assertError(function() BigInt('0x0x10') end, 'invalid number format: 0x0x10')
assertError(function() BigInt('0xF', 10) end, 'invalid number format: 0xF')
assertError(function() BigInt('0xF', 16) end, 'invalid number format: 0xF')
assertError(function() BigInt('1.2') end, 'invalid number format: 1.2')
assertError(function() BigInt('1e10') end, 'invalid number format: 1e10')
assertError(function() BigInt('1E10') end, 'invalid number format: 1E10')
assertError(function() BigInt('0xFp10') end, 'invalid number format: 0xFp10')
assertError(function() BigInt('0xFP10') end, 'invalid number format: 0xFP10')
assertError(function() BigInt(1ULL) end, 'invalid number format: 1ULL')

assertError(function() BigInt(1, 10) end, 'do not provide a base with a number')
assertError(function() BigInt(0xF, 10) end, 'do not provide a base with a number')
assertError(function() BigInt(0xF, 16) end, 'do not provide a base with a number')

assertError(function() BigInt(0/0) end, 'not a number')
assertError(function() BigInt(1/0) end, 'number too large')
assertError(function() BigInt(2^512) end, 'number too large')
assertError(function() BigInt(math.huge) end, 'number too large')

end

print(sw)