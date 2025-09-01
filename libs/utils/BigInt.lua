local class = require('../class')
local typing = require('../typing')

local Digits = require('./Digits')

local STORAGE_BASE = 2^16

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

local function checkBase(base)
	return typing.checkInteger(base, 10, 2, 36)
end

local BigInt = class('BigInt')

function BigInt._debug(base) STORAGE_BASE = base end

local function checkDigits(obj, inputBase, outputBase, makeCopy)

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

		return Digits.fromNumber(n, outputBase)

	elseif t == 'string' then

		return Digits.fromString(obj, inputBase, outputBase)

	elseif t == 'table' then

		if inputBase then
			error('do not provide a base with a table')
		end

		local digits
		if class.isInstance(obj, BigInt) then
			digits = obj._digits
		elseif Digits.isInstance(obj) then
			digits = obj
		else
			error('invalid digit table')
		end

		if digits.base == outputBase then
			return makeCopy and digits:copy() or digits
		else
			return digits:convert(outputBase)
		end

	end

	error('invalid number format: ' .. tostring(obj))

end

function BigInt:__init(obj, inputBase)
	self._digits = checkDigits(obj, inputBase and checkBase(inputBase), nil, true)
end

function BigInt:toString(outputBase, len)
	outputBase = outputBase and checkBase(outputBase)
	len = len and typing.checkInteger(len, 10, 1)
	return self._digits:toString(outputBase, len)
end

function BigInt:toNumber()
	return self._digits:toNumber()
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
		local c = a:getSum(b)
		c.sign = rawget(a, 'sign')
		return BigInt(c)
	else
		local comp = a:compare(b)
		if comp == true then
			local c = b:getDifference(a)
			c.sign = rawget(b, 'sign')
			return BigInt(c)
		elseif comp == false then
			local c = a:getDifference(b)
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
		local c = a:getSum(b)
		c.sign = rawget(a, 'sign')
		return BigInt(c)
	else
		local comp = a:compare(b)
		if comp == true then
			local c = b:getDifference(a)
			if #c > 0 and a.sign == 0 then
				c.sign = 1
			end
			return BigInt(c)
		elseif comp == false then
			local c = a:getDifference(b)
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

	local c = a:getProduct(b)
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

	local comp = a:compare(b)

	if comp == true then

		if a.sign == b.sign then
			return BigInt(0)
		else
			return BigInt(-1)
		end

	elseif comp == false then -- only supports base 2

		a = a.base ~= 2 and a:convert(2) or a
		b = b.base ~= 2 and b:convert(2) or b

		local c = Digits(2)
		local r = Digits(2)
		for i = #a, 1, -1 do
			if #r ~= 0 or a[i] ~= 0 then
				table.insert(r, 1, a[i])
			end
			if not r:compare(b) then
				r:subtractInPlace(b)
				c[i] = 1
			else
				c[i] = 0
			end
		end
		c:trim()
		if a.sign ~= b.sign then
			if #r > 0 then
				if #c == 0 then
					c = Digits.negativeOne()
				else
					c:addInPlace(Digits.positiveOne(c.base))
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
	local c = Digits.positiveOne(a.base)
	local i = Digits(b.base)
	for k, v in pairs(b) do
		i[k] = v
	end

	local one = Digits.positiveOne(i.base)
	if a.sign == 0 then
		repeat
			c = c:getProduct(a)
			i:subtractInPlace(one)
		until #i == 0
	else
		local sign = c.sign
		repeat
			c = c:getProduct(a)
			i:subtractInPlace(one)
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
	local new = Digits(old.base)
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
	local c = a:bitop(b, 'AND')
	return BigInt(c)
end

function BigInt:__bor(other)
	local b = checkDigits(other, nil, 2)
	if #b == 0 then
		return BigInt(self)
	end
	local a = checkDigits(self, nil, 2)
	local c = a:bitop(b, 'OR')
	return BigInt(c)
end

function BigInt:__bxor(other)
	local b = checkDigits(other, nil, 2)
	if #b == 0 then
		return BigInt(self)
	end
	local a = checkDigits(self, nil, 2)
	local c = a:bitop(b, 'XOR')
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
		local comp = a:compare(b)
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
		local comp = a:compare(b)
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