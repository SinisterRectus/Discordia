local ffi = require('ffi')
local class = require('class')

local Buffer = class('Buffer')

local C = ffi.os == 'Windows' and ffi.load('msvcrt') or ffi.C

local concat = table.concat
local lshift, rshift = bit.lshift, bit.rshift
local tohex = bit.tohex
local gc, cast, copy, fill = ffi.gc, ffi.cast, ffi.copy, ffi.fill
local ffi_string = ffi.string
local min = math.min

ffi.cdef [[
void* malloc(size_t size);
void* calloc(size_t num, size_t size);
void free(void *ptr);
]]

function Buffer:__init(str)
	if type(str) == 'string' then
		self._len = #str
		self._cdata = gc(cast('unsigned char*', C.calloc(self._len, 1)), C.free)
		copy(self._cdata, str, self._len)
	else
		self._len = tonumber(str) or 0
		self._cdata = gc(cast('unsigned char*', C.calloc(self._len, 1)), C.free)
	end
end

function Buffer:__len()
	return self._len
end

function Buffer:__tostring()
	return ffi_string(self._cdata, self._len)
end

local function get(self, k)
	if k < 0 or k > self._len then
		return error('buffer index out of bounds')
	end
	return self._cdata[k]
end

local function set(self, k, v)
	if k < 0 or k > self._len then
		return error('buffer index out of bounds')
	end
	self._cdata[k] = v
end

local function complement8(value)
	return value < 0x80 and value or value - 0x100
end

local function complement16(value)
	return value < 0x8000 and value or value - 0x10000
end

function Buffer:readUInt8(k)
		return get(self, k)
end

function Buffer:readUInt16BE(k)
	return lshift(get(self, k), 8) + get(self, k + 1)
end

function Buffer:readUInt16LE(k)
	return get(self, k) + lshift(get(self, k + 1), 8)
end

function Buffer:readUInt32BE(k)
	return get(self, k) * 0x1000000 + lshift(get(self, k + 1), 16) + lshift(get(self, k + 2), 8) + get(self, k + 3)
end

function Buffer:readUInt32LE(k)
	return get(self, k) + lshift(get(self, k + 1), 8) + lshift(get(self, k + 2), 16) + get(self, k + 3) * 0x1000000
end

function Buffer:readInt8(k)
	return complement8(self:readUInt8(k))
end

function Buffer:readInt16BE(k)
	return complement16(self:readUInt16BE(k))
end

function Buffer:readInt16LE(k)
	return complement16(self:readUInt16LE(k))
end

function Buffer:readInt32BE(k)
	return lshift(get(self, k), 24) + lshift(get(self, k + 1), 16) + lshift(get(self, k + 2), 8) + get(self, k + 3)
end

function Buffer:readInt32LE(k)
	return get(self, k) + lshift(get(self, k + 1), 8) + lshift(get(self, k + 2), 16) + lshift(get(self, k + 3), 24)
end

function Buffer:writeUInt8(k, v)
	set(self, k, rshift(v, 0))
end

function Buffer:writeUInt16BE(k, v)
	set(self, k, rshift(v, 8))
	set(self, k + 1, rshift(v, 0))
end

function Buffer:writeUInt16LE(k, v)
	set(self, k, rshift(v, 0))
	set(self, k + 1, rshift(v, 8))
end

function Buffer:writeUInt32BE(k, v)
	set(self, k, rshift(v, 24))
	set(self, k + 1, rshift(v, 16))
	set(self, k + 2, rshift(v, 8))
	set(self, k + 3, rshift(v, 0))
end

function Buffer:writeUInt32LE(k, v)
	set(self, k, rshift(v, 0))
	set(self, k + 1, rshift(v, 8))
	set(self, k + 2, rshift(v, 16))
	set(self, k + 3, rshift(v, 24))
end

Buffer.writeInt8 = Buffer.writeUInt8
Buffer.writeInt16BE = Buffer.writeUInt16BE
Buffer.writeInt16LE = Buffer.writeUInt16LE
Buffer.writeInt32BE = Buffer.writeUInt32BE
Buffer.writeInt32LE = Buffer.writeUInt32LE

function Buffer:read(offset, len)
	offset = offset or 0
	len = len or self._len
	return ffi_string(self._cdata + offset, min(len, self._len - offset))
end

function Buffer:write(str, offset, len)
	offset = offset or 0
	len = len or #str
	return copy(self._cdata + offset, str, min(len, self._len - offset))
end

function Buffer:fill(v)
	return fill(self._cdata, self._len, v)
end

function Buffer:toHex(i, j)
	local str = {}
	i = i or 0
	j = j or self._len
	for n = i, j - 1 do
		str[n + 1] = tohex(get(self, n), 2)
	end
	return concat(str, ' ')
end

function Buffer:toArray(i, j)
	local tbl = {}
	i = i or 0
	j = j or self._len
	for n = i, j - 1 do
		tbl[n + 1] = get(self, n)
	end
	return tbl
end

return Buffer
