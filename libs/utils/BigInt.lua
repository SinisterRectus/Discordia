local class = require('../class')
local typing = require('../typing')

local meta = {__index = function() return 0 end}
local function array(base)
	return setmetatable({base = typing.checkInteger(base, 10, 2)}, meta)
end

local codec = setmetatable({}, {__index = function(_, k) return k end})
for n, char in ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('()(.)') do
	codec[n - 1] = char
end

local DEFAULT_BASE = 10
local STORAGE_BASE = 2^16

local function positiveOne(base)
	local digits = array(base)
	digits[1] = 1
	return digits
end

local function negativeOne(base)
	local digits = array(base)
	digits[1] = 1
	digits.sign = 1
	return digits
end

local bitops = {
	['AND'] = function(a, b) return a == 1 and b == 1 end,
	['OR'] = function(a, b) return a == 1 or b == 1 end,
	['XOR'] = function(a, b) return a ~= b end,
}

local prefixes = {
	['0b'] = 02, ['0B'] = 02,
	['0o'] = 08, ['0O'] = 08,
	['0x'] = 16, ['0X'] = 16,
}

--[[
Implementation Details

DEFAULT_BASE should be 10, unless we're in a world where 10 is not the standard
base used in arithmetic.

STORAGE_BASE can theoretically be any integer greater than 1, but should be
chosen so that digit operations do not exceed a max safe int. This limit could
be exceeded if digits were recursively wrapped as bigints until their operations
no longer exceed a max safe int, but this adds significant complexity.

Storage and operations:

	Digits are stored in an array-like table using little-endian ordering.
	
	Undefined elements of this table default to 0 by __index metamethod.

	Signs are keyed as the 'sign' value of the digit table. A value of nil,
	which defaults to 0, indicates positive while a value of 1 indicates
	negative.

	Lua's __eq metamethods are unfortiunately only invoked for equal types.
	As a consequence, BigInt(n) == n is false while BigInt(n) <= n is true.

	Since BigInts are tables, they are reference-types. Thus, they are passed by
	reference and a direct assignment such as n = m does not produce a copy.
	To match value-type behavior, use n = m:copy(). Additionally, all BigInt
	operators do not modify objects in-place and instead return new objects.
	Therefore, in the case of m = -n, m is a new object and an explicit call to
	the copy method is redundant.

	As an optimization, digit tables are shared between BigInt objects. Do not
	directly modify at-rest digit tables as other BigInts may reference them.

	Division only supports base 2 digits and is therefore the only arithmetic
	operation here that does not support an arbitrary base. This may change in
	the future depending on needs.

	Division and floor division are equivalent such that a / b == a // b.
	
	Modulo is arithmetic such that a % b == a - a // b * b

	Bitwise operations are two's complemented:
		AND, OR, and XOR use logical bitwise comparisons
		NOT is arithmetic such that ~a == -a - 1
		Left shift is arithmetic such that a << b == a * 2 ^ b
		Right shift is arithmetic such that a >> b == a / 2 ^ b

	Standard math operations are not implemented. Maybe one day.

Input formats:

	BigInt(n, base) where n is a number or numerical string and base is an
	optional number from 2 through 36 inclusive. The default base is defined
	by a string prefix (see below) or DEFAULT_BASE.
 
	Numbers are accepted except for those that are too large to be represented
	without precision loss (such that n + 1 == n) or are "not a number"
	(such that n ~= n). Fractions are floored. If a number and base are provided
	at the same time, the input is rejected.

	Big-endian sign-magnitude numerical strings are supported. Leading and
	trailing whitespace is ignored. Unary positive (+) and negative (-) signs
	are supported. Binary (0b), octal (0o), and hexadeximal (0x) prefixes are
	supported if a base is not declared; otherwise, the whole string is
	consumed according to the declared base. Leading zeroes are ignored.
	Fraction parts are not supported. Exponent parts are not supported.

	LuaJIT integers are not supported. Users should convert them to appropriate
	numbers or strings.

	The following are valid and equivalent representations for 15:
		BigInt(15)
		BigInt('0b1111')
		BigInt('0B1111')
		BigInt('1111', 2)
		BigInt('0o17')
		BigInt('0O17')
		BigInt('17', 8)
		BigInt('15')
		BigInt('15', 10)
		BigInt('0xF')
		BigInt('0XF')
		BigInt('F', 16)

Output formats:

	BigInt:toString(base) returns a big-endian sign-magnitude numerical string
	that represents the bigint according to the provided base, an optional
	number from 2 through 36 inclusive. The default base is defined by
	DEFAUT_BASE. For digits greater than 9, uppercase letters [A-Z] are used.

	BigInt:toNumber() returns a Lua number that represents the bigint.
	Sufficiently large integers may lose precision on conversion.

	In Discordia, the generic class __tostring metamethod uses toString methods
	where string.format('%s: %s', obj.__name, obj:toString()) is the output.
]]

local function trim(digits)
	local i = #digits
	while i > 0 and digits[i] == 0 do
		digits[i] = nil
		i = i - 1
	end
end

local function compare(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	if n < m then
		return true
	elseif n > m then
		return false
	end
	for i = n, 1, -1 do
		if a[i] < b[i] then
			return true
		elseif a[i] > b[i] then
			return false
		end
	end
	return nil
end

local function setDigit(digits, i, v)
	if v >= digits.base then
		local n = math.floor(v / digits.base)
		digits[i + 1] = digits[i + 1] + n
		digits[i] = v - n * digits.base
	elseif v < 0 then
		local n = math.ceil(-v / digits.base)
		digits[i + 1] = digits[i + 1] - n
		digits[i] = v + n * digits.base
	else
		digits[i] = v
	end
end

local function getSum(a, b) -- unsigned
	assert(a.base == b.base)
	local c = array(a.base)
	for i = 1, math.max(#a, #b) do
		setDigit(c, i, c[i] + a[i] + b[i])
	end
	return c
end

local function addInPlace(a, b) -- unsigned
	assert(a.base == b.base)
	for i = 1, math.max(#a, #b) do
		setDigit(a, i, a[i] + b[i])
	end
end

local function getDifference(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	assert(n >= m)
	local c = array(a.base)
	for i = 1, n do
		setDigit(c, i, c[i] + a[i] - b[i])
	end
	trim(c)
	return c
end

local function subtractInPlace(a, b) -- unsigned
	assert(a.base == b.base)
	local n, m = #a, #b
	assert(n >= m)
	for i = 1, n do
		setDigit(a, i, a[i] - b[i])
	end
	trim(a)
end

local function getProduct(a, b) -- unsigned
	assert(a.base == b.base)
	local c = array(a.base)
	for i = 1, #a do
		for j = 1, #b do
			local k = i + j - 1
			setDigit(c, k, c[k] + a[i] * b[j])
		end
	end
	return c
end

local function getComplement(digits, n)
	assert(digits.base == 2)
	local complement = array(2)
	for i = 1, n do
		complement[i] = math.abs(digits[i] - 1)
	end
	addInPlace(complement, positiveOne(2))
	return complement
end

local function complementInPlace(digits, n)
	assert(digits.base == 2)
	for i = 1, n do
		digits[i] = math.abs(digits[i] - 1)
	end
	addInPlace(digits, positiveOne(2))
end

local function bitop(a, b, fn)

	assert(a.base == 2)
	assert(b.base == 2)
	local n = math.max(#a, #b)
	local signed = fn(a.sign, b.sign)

	if a.sign == 1 then
		a = getComplement(a, n)
	end

	if b.sign == 1 then
		b = getComplement(b, n)
	end

	local c = array(a.base)
	for i = 1, n do
		c[i] = fn(a[i], b[i]) and 1 or 0
	end

	if signed then
		complementInPlace(c, n)
		c.sign = 1
	end

	trim(c)
	return c

end

local function parseUnsigned(n, base)
	local digits = array(base)
	while n > 0 do
		local r = n % base
		table.insert(digits, r)
		n = (n - r) / base
	end
	return digits
end

local function parseSigned(n, base)
	local sign = nil
	if n < 0 then
		sign = 1
		n = -n
	end
	local digits = parseUnsigned(n, base)
	digits.sign = sign
	return digits
end

local function checkDigit(str, i, base)
	local digit = tonumber(str:sub(i, i), base)
	if not digit then
		return error('invalid number format: ' .. str)
	end
	return digit
end

local function checkBase(base)
	return typing.checkInteger(base, 10, 2, 36)
end

local function parseString(str, inputBase, outputBase) -- BE string to LE array

	local digits = array(outputBase)

	local a, b = 1, #str

	local _, j = str:find('^%s+', a)
	if j then a = j + 1 end -- ignore leading whitespace

	local k = str:find('%s+$', a)
	if k then b = k - 1 end -- ignore trailing whitespace

	-- consume sign
	local sign = str:sub(a, a)
	if sign == '-' then
		sign = 1
		a = a + 1
	elseif sign == '+' then
		sign = nil
		a = a + 1
	else
		sign = nil
	end

	if not inputBase then -- define inputBase
		local prefix = prefixes[str:sub(a, a + 1)]
		if prefix then
			inputBase = prefix
			a = a + 2
		else
			inputBase = DEFAULT_BASE
		end
	end

	local _, z = str:find('^0+', a)
	if z then a = z + 1 end -- ignore leading zeroes

	if inputBase == outputBase then
		for i = b, a, -1 do
			local digit = checkDigit(str, i, inputBase)
			table.insert(digits, digit)
		end
	else
		local base = parseUnsigned(inputBase, outputBase)
		for i = a, b, 1 do
			local digit = parseUnsigned(checkDigit(str, i, inputBase), outputBase)
			digits = getProduct(digits, base)
			addInPlace(digits, digit)
		end
	end

	digits.sign = #digits > 0 and sign

	return digits

end

local function convertDigits(old, outputBase)
	local new = array(outputBase)
	local base = parseUnsigned(old.base, outputBase)
	for i = #old, 1, -1 do
		local digit = parseUnsigned(old[i], outputBase)
		new = getProduct(new, base)
		addInPlace(new, digit)
	end
	new.sign = rawget(old, 'sign')
	return new
end

local BigInt = class('BigInt')

function BigInt._debug(base) STORAGE_BASE = base end

local function checkDigits(obj, inputBase, outputBase)

	outputBase = outputBase or STORAGE_BASE

	local t = type(obj)

	if t == 'number' then

		if inputBase then
			error('do not provide a base with a number')
		end

		local n = math.floor(obj)

		if n ~= n then
			error('not a number')
		end

		if n + 1 == n then
			error('number too large')
		end

		return parseSigned(n, outputBase)

	elseif t == 'string' then

		return parseString(obj, inputBase, outputBase)

	elseif t == 'table' then

		if inputBase then
			error('do not provide a base with a table')
		end

		local digits
		if class.isInstance(obj, BigInt) then
			digits = obj._digits
		elseif getmetatable(obj) == meta then
			digits = obj
		else
			error('invalid digit table')
		end

		if digits.base == outputBase then
			return digits
		else
			return convertDigits(digits, outputBase)
		end

	end

	error('invalid number format: ' .. tostring(obj))

end

function BigInt:__init(obj, inputBase)
	self._digits = checkDigits(obj, inputBase and checkBase(inputBase))
end

function BigInt:toString(outputBase)

	local digits = self._digits
	if #digits == 0 then
		return '0'
	elseif #digits == 1 and digits[1] == 1 then
		if digits.sign == 0 then
			return '1'
		elseif digits.sign == 1 then
			return '-1'
		end
	end

	outputBase = outputBase and checkBase(outputBase) or DEFAULT_BASE
	if digits.base ~= outputBase then
		digits = convertDigits(digits, outputBase)
	end

	local buf = {}

	if digits.sign == 1 then
		table.insert(buf, '-')
	end

	for i = #digits, 1, -1 do
		table.insert(buf, codec[digits[i]])
	end

	return table.concat(buf)

end

function BigInt:toNumber()
	local n = 0
	local digits = self._digits
	for i = #digits, 1, -1 do
		n = n * digits.base + digits[i]
	end
	return digits.sign == 1 and -n or n
end

function BigInt:copy()
	return BigInt(self)
end

function BigInt:__add(other)

	local a = checkDigits(self)
	if #a == 0 then
		return BigInt(other)
	end

	local b = checkDigits(other)
	if #b == 0 then
		return BigInt(self)
	end

	if a.sign == b.sign then
		local c = getSum(a, b)
		c.sign = rawget(a, 'sign')
		return BigInt(c)
	else
		local comp = compare(a, b)
		if comp == true then
			local c = getDifference(b, a)
			c.sign = rawget(b, 'sign')
			return BigInt(c)
		elseif comp == false then
			local c = getDifference(a, b)
			c.sign = rawget(a, 'sign')
			return BigInt(c)
		elseif comp == nil then
			return BigInt(0)
		end
	end

end

function BigInt:__sub(other)

	local a = checkDigits(self)
	if #a == 0 then
		return -BigInt(other)
	end

	local b = checkDigits(other)
	if #b == 0 then
		return BigInt(self)
	end

	if a.sign ~= b.sign then
		local c = getSum(a, b)
		c.sign = rawget(a, 'sign')
		return BigInt(c)
	else
		local comp = compare(a, b)
		if comp == true then
			local c = getDifference(b, a)
			if #c > 0 and a.sign == 0 then
				c.sign = 1
			end
			return BigInt(c)
		elseif comp == false then
			local c = getDifference(a, b)
			c.sign = rawget(a, 'sign')
			return BigInt(c)
		elseif comp == nil then
			return BigInt(0)
		end
	end

end

function BigInt:__mul(other)

	local a = checkDigits(self)
	if #a == 0 then
		return BigInt(0)
	end

	if #a == 1 and a[1] == 1 then
		if a.sign == 0 then
			return BigInt(other)
		elseif a.sign == 1 then
			return -BigInt(other)
		end
	end

	local b = checkDigits(other)
	if #b == 0 then
		return BigInt(0)
	end

	if #b == 1 and b[1] == 1 then
		if b.sign == 0 then
			return BigInt(self)
		else
			return -BigInt(self)
		end
	end

	local c = getProduct(a, b)
	if a.sign ~= b.sign then
		c.sign = 1
	end
	return BigInt(c)

end

function BigInt:__div(other)

	local b = checkDigits(other)
	if #b == 0 then
		return error('cannot divide by 0')
	end

	if #b == 1 and b[1] == 1 then
		if b.sign == 0 then
			return BigInt(self)
		elseif b.sign == 1 then
			return -BigInt(self)
		end
	end

	local a = checkDigits(self)
	if #a == 0 then
		return BigInt(0)
	end

	local comp = compare(a, b)

	if comp == true then

		if a.sign == b.sign then
			return BigInt(0)
		else
			return BigInt(-1)
		end

	elseif comp == false then -- only supports base 2

		a = a.base ~= 2 and convertDigits(a, 2) or a
		b = b.base ~= 2 and convertDigits(b, 2) or b

		local c = array(2)
		local r = array(2)
		for i = #a, 1, -1 do
			if #r ~= 0 or a[i] ~= 0 then
				table.insert(r, 1, a[i])
			end
			if not compare(r, b) then
				subtractInPlace(r, b)
				c[i] = 1
			else
				c[i] = 0
			end
		end
		trim(c)

		if a.sign ~= b.sign then
			if #r > 0 then
				if #c == 0 then
					c = negativeOne()
				else
					addInPlace(c, positiveOne(c.base))
				end
			end
			c.sign = 1
		end
		return BigInt(c)

	elseif comp == nil then

		if a.sign == b.sign then
			return BigInt(1)
		else
			return BigInt(-1)
		end

	end

end

BigInt.__idiv = BigInt.__div -- integer division is integer division

function BigInt:__mod(other)
	return self - self / other * other
end

function BigInt:__pow(other)

	local b = checkDigits(other)
	if b.sign == 1 then
		return error('cannot raise bigint to negative power')
	end

	if #b == 0 then
		return BigInt(1)
	end

	if #b == 1 and b[1] == 1 then
		return BigInt(self)
	end
	
	local a = checkDigits(self)
	local c = positiveOne(a.base)
	local i = array(b.base)
	for k, v in pairs(b) do
		i[k] = v
	end

	local one = positiveOne(i.base)
	if a.sign == 0 then
		repeat
			c = getProduct(c, a)
			subtractInPlace(i, one)
		until #i == 0
	else
		local sign = c.sign
		repeat
			c = getProduct(c, a)
			subtractInPlace(i, one)
			sign = math.abs(sign - 1)
		until #i == 0
		c.sign = sign == 1 and sign or nil
	end

	return BigInt(c)

end

function BigInt:__unm()
	local old = self._digits
	if #old == 0 then
		return BigInt(0)
	end
	local new = array(old.base)
	for i, v in ipairs(old) do
		new[i] = v
	end
	if old.sign == 0 then
		new.sign = 1
	end
	return BigInt(new)
end

function BigInt:__band(other)
	local b = checkDigits(other, nil, 2)
	if #b == 0 then
		return BigInt(0)
	end
	local a = checkDigits(self, nil, 2)
	local c = bitop(a, b, bitops.AND)
	return BigInt(c)
end

function BigInt:__bor(other)
	local b = checkDigits(other, nil, 2)
	if #b == 0 then
		return BigInt(self)
	end
	local a = checkDigits(self, nil, 2)
	local c = bitop(a, b, bitops.OR)
	return BigInt(c)
end

function BigInt:__bxor(other)
	local b = checkDigits(other, nil, 2)
	if #b == 0 then
		return BigInt(self)
	end
	local a = checkDigits(self, nil, 2)
	local c = bitop(a, b, bitops.XOR)
	return BigInt(c)
end

function BigInt:__bnot()
	return - self - 1
end

function BigInt:__shl(other)
	return self * 2 ^ other
end

function BigInt:__shr(other)
	return self / 2 ^ other
end

function BigInt:__eq(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	if a.sign ~= b.sign then
		return false
	else
		local n, m = #a, #b
		if n ~= m then
			return false
		end
		for i = n, 1, -1 do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	end
end

function BigInt:__lt(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	if a.sign < b.sign then
		return false
	elseif a.sign > b.sign then
		return true
	else
		local comp = compare(a, b)
		if comp == nil then
			return false
		elseif a.sign == 1 then
			return not comp
		else
			return comp
		end
	end
end

function BigInt:__le(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	if a.sign < b.sign then
		return false
	elseif a.sign > b.sign then
		return true
	else
		local comp = compare(a, b)
		if comp == nil then
			return true
		elseif a.sign == 1 then
			return not comp
		else
			return comp
		end
	end
end

return BigInt