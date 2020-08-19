local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local reverse = string.reverse
local insert, concat = table.insert, table.concat
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local lshift = bit.lshift
local isInstance = class.isInstance
local checkInteger = typing.checkInteger
local str2int = helpers.str2int

local codec = {}
for n, char in ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('()(.)') do
	codec[n - 1] = char
end

local function checkBase(base)
	return checkInteger(base, 10, 2, 36)
end

local function checkLength(len)
	return checkInteger(len, 10, 1)
end

local function checkValue(value, base)
	base = base and checkBase(base) or 10
	checkInteger(value, base, 0, 0xFFFFFFFFFFFFFFFF)
	local t = type(value)
	if t == 'number' then
		return value + 0ULL
	elseif t == 'string' then
		return str2int(value, base)
	elseif t == 'cdata' then
		return value
	end
end

local function checkBit(bit)
	return checkInteger(bit, 10, 1, 64)
end

local Bitfield, get = class('Bitfield')

local function checkBitfield(obj)
	if isInstance(obj, Bitfield) then
		return obj.value
	end
	return error('cannot perform operation', 2)
end

function Bitfield:__init(v, base)
	self._value = v and checkValue(v, base) or 0ULL
end

function Bitfield:__eq(other)
	return checkBitfield(self) == checkBitfield(other)
end

function Bitfield:__lt(other)
	return checkBitfield(self) < checkBitfield(other)
end

function Bitfield:__le(other)
	return checkBitfield(self) <= checkBitfield(other)
end

function Bitfield:__add(other)
	return Bitfield(checkBitfield(self) + checkBitfield(other))
end

function Bitfield:__sub(other)
	return Bitfield(checkBitfield(self) - checkBitfield(other))
end

function Bitfield:__mod(other)
	return Bitfield(checkBitfield(self) % checkBitfield(other))
end

function Bitfield:__mul(other)
	if tonumber(other) then
		return Bitfield(checkBitfield(self) * other)
	elseif tonumber(self) then
		return Bitfield(self * checkBitfield(other))
	else
		return error('cannot perform operation')
	end
end

function Bitfield:__div(other)
	if tonumber(other) then
		return Bitfield(checkBitfield(self) / other)
	elseif tonumber(self) then
		return error('division not commutative')
	else
		return error('cannot perform operation')
	end
end

function Bitfield:toString(base, len)
	local n = self.value
	local ret = {}
	base = base and checkBase(base) or 2
	len = len and checkLength(len) or 1
	while n > 0 do
		local r = n % base
		insert(ret, codec[tonumber(r)])
		n = (n - r) / base
	end
	while #ret < len do
		insert(ret, '0')
	end
	return reverse(concat(ret))
end

function Bitfield:toBin(len)
	return self:toString(2, len)
end

function Bitfield:toOct(len)
	return self:toString(8, len)
end

function Bitfield:toDec(len)
	return self:toString(10, len)
end

function Bitfield:toHex(len)
	return self:toString(16, len)
end

function Bitfield:enableBit(n) -- 1-indexed
	n = checkBit(n)
	return self:enableValue(lshift(1ULL, n - 1))
end

function Bitfield:disableBit(n) -- 1-indexed
	n = checkBit(n)
	return self:disableValue(lshift(1ULL, n - 1))
end

function Bitfield:toggleBit(n) -- 1-indexed
	n = checkBit(n)
	return self:toggleValue(lshift(1ULL, n - 1))
end

function Bitfield:hasBit(n) -- 1-indexed
	n = checkBit(n)
	return self:hasValue(lshift(1ULL, n - 1))
end

function Bitfield:enableValue(v, base)
	v = checkValue(v, base)
	self._value = bor(self._value, v)
end

function Bitfield:disableValue(v, base)
	v = checkValue(v, base)
	self._value = band(self._value, bnot(v))
end

function Bitfield:toggleValue(v, base)
	v = checkValue(v, base)
	self._value = bxor(self._value, v)
end

function Bitfield:hasValue(v, base)
	v = checkValue(v, base)
	return band(self._value, v) == v
end

function Bitfield:union(other) -- bits in either A or B
	return Bitfield(bor(checkBitfield(self), checkBitfield(other)))
end

function Bitfield:complement(other) -- bits in A but not in B
	return Bitfield(band(checkBitfield(self), bnot(checkBitfield(other))))
end

function Bitfield:difference(other) -- bits in A or B but not in both
	return Bitfield(bxor(checkBitfield(self), checkBitfield(other)))
end

function Bitfield:intersection(other) -- bits in both A and B
	return Bitfield(band(checkBitfield(self), checkBitfield(other)))
end

----

function get:value()
	return self._value
end

return Bitfield
