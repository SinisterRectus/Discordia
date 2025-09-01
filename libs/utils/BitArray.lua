local class = require('../class')
local typing = require('../typing')

local Digits = require('./Digits')

local function checkBase(base)
	return typing.checkInteger(base, 10, 2, 36)
end

local function checkBit(bit)
	return typing.checkInteger(bit, 10, 1)
end

local BitArray = class('BitArray')

local function checkDigits(obj, inputBase, makeCopy)

	local t = type(obj)

	if t == 'number' then

		local n = typing.checkInteger(obj, inputBase, 0, 2^64)
		return Digits.fromNumber(n, 2)

	elseif t == 'string' then

		typing.checkInteger(obj, inputBase, 0)
		return Digits.fromString(obj, inputBase, 2)

	elseif t == 'table' then

		if inputBase then
			error('do not provide a base with a table')
		end

		if class.isInstance(obj, BitArray) then
			return makeCopy and obj._digits:copy() or obj._digits
		elseif Digits.isInstance(obj) then
			return makeCopy and obj:copy() or obj
		else
			local max = 0
			local digits = Digits(2)
			for _, v in pairs(obj) do
				local n = checkBit(v)
				digits[n] = 1
				if n > max then
					max = n
				end
			end
			digits:fill(max)
			return digits
		end

	elseif t == 'nil' then

		return Digits.fromNumber(0, 2)

	end

	error('invalid number format: ' .. tostring(obj))

end

function BitArray:__init(obj, inputBase)
	inputBase = inputBase and checkBase(inputBase)
	self._digits = checkDigits(obj, inputBase, true)
end

function BitArray:toString(outputBase, len)
	outputBase = outputBase and checkBase(outputBase) or 2
	len = len and typing.checkInteger(len, 10, 1)
	return self._digits:toString(outputBase, len)
end

function BitArray:toBin(len)
	return self:toString(2, len)
end

function BitArray:toOct(len)
	return self:toString(8, len)
end

function BitArray:toDec(len)
	return self:toString(10, len)
end

function BitArray:toHex(len)
	return self:toString(16, len)
end

function BitArray:toNumber()
	return self._digits:toNumber()
end

function BitArray:toTable(filter)
	local tbl = {}
	for k, v in pairs(typing.checkType('table', filter)) do
		tbl[k] = self:hasBit(v)
	end
	return tbl
end

function BitArray:copy()
	return BitArray(self)
end

function BitArray:__eq(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
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

function BitArray:hasBit(n)
	n = checkBit(n)
	return self._digits[n] == 1
end

function BitArray:enableBit(n)
	n = checkBit(n)
	self._digits:fill(n - 1)
	self._digits[n] = 1
end

function BitArray:disableBit(n)
	n = checkBit(n)
	self._digits[n] = 0
	self._digits:trim()
end

function BitArray:toggleBit(n)
	n = checkBit(n)
	self._digits[n] = math.abs(self._digits[n] - 1)
	self._digits:trim()
end

function BitArray:union(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	local c = a:bitop(b, 'OR')
	return BitArray(c)
end

function BitArray:intersection(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	local c = a:bitop(b, 'AND')
	return BitArray(c)
end

function BitArray:difference(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	local c = Digits(2)
	for i in ipairs(b) do
		c[i] = math.abs(b[i] - 1)
	end
	c = a:bitop(c, 'AND')
	return BitArray(c)
end

function BitArray:symmetricDifference(other)
	local a = checkDigits(self)
	local b = checkDigits(other)
	local c = a:bitop(b, 'XOR')
	return BitArray(c)
end

return BitArray