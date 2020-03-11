local class = require('../class')

local reverse = string.reverse
local insert, concat = table.insert, table.concat
local band, bor, bnot, bxor = bit.band, bit.bor, bit.bnot, bit.bxor
local lshift = bit.lshift

local codec = {}
do
	local alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	local base = #alphabet
	for char in alphabet:gmatch('.') do
		codec[tonumber(char, base)] = char
	end
end

local function checkBase(base)
	if not pcall(tonumber, 0, base) then
		return error('invalid base', 2)
	end
	return base
end

local function optBase(base, default)
	if base == nil then
		return default
	end
	return checkBase(base)
end

local function toNumber(value, base)
	if type(value) == 'table' then
		local n = 0
		for _, v in pairs(value) do
			v = toNumber(v, base)
			n = bor(n, v)
		end
		return n
	else
		return tonumber(value, base)
	end
end

local Bitfield, get = class('Bitfield')

function Bitfield:__init(v)
	self._value = toNumber(v) or 0
end

function Bitfield:toString(base, len)
	local n = self._value
	local ret = {}
	base = optBase(base, 2)
	while n > 0 do
		local r = n % base
		insert(ret, codec[r])
		n = (n - r) / base
	end
	while #ret < (len or 1) do
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
	return self:enableValue(lshift(1, n - 1))
end

function Bitfield:disableBit(n) -- 1-indexed
	return self:disableValue(lshift(1, n - 1))
end

function Bitfield:toggleBit(n) -- 1-indexed
	return self:toggleValue(lshift(1, n - 1))
end

function Bitfield:hasBit(n) -- 1-indexed
	return self:hasValue(lshift(1, n - 1))
end

function Bitfield:enableValue(v, base)
	v = toNumber(v, base)
	self._value = bor(self._value, v)
end

function Bitfield:disableValue(v, base)
	v = toNumber(v, base)
	self._value = band(self._value, bnot(v))
end

function Bitfield:toggleValue(v, base)
	v = toNumber(v, base)
	self._value = bxor(self._value, v)
end

function Bitfield:hasValue(v, base)
	v = toNumber(v, base)
	return band(self._value, v) == v
end

function Bitfield:union(other) -- bits in either A or B
	return Bitfield(bor(self.value, other.value))
end

function Bitfield:complement(other) -- bits in A but not in B
	return Bitfield(band(self.value, bnot(other.value)))
end

function Bitfield:difference(other) -- bits in A or B but not in both
	return Bitfield(bxor(self.value, other.value))
end

function Bitfield:intersection(other) -- bits in both A and B
	return Bitfield(band(self.value, other.value))
end

----

function get:value()
	return self._value
end

return Bitfield
