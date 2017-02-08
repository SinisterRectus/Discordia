local Buffer, _, method = class('Buffer')
Buffer.__description = "Modified version of Luvit's low-level buffer class."

local ffi = require('ffi')

local concat = table.concat
local gc, cast, ffi_copy, ffi_string = ffi.gc, ffi.cast, ffi.copy, ffi.string
local lshift, rshift, tohex, tobit = bit.lshift, bit.rshift, bit.tohex, bit.tobit

ffi.cdef[[
	void *malloc(size_t size);
	void *calloc(size_t num, size_t size);
	void *realloc(void *ptr, size_t size);
	void free(void *ptr);
]]

local C = ffi.os == 'Windows' and ffi.load('msvcrt') or ffi.C

function Buffer:__init(arg)
	if type(arg) == 'number' then
		self._len = arg
		self._cdata = gc(cast('unsigned char*', C.calloc(arg, 1)), C.free)
	elseif type(arg) == 'string' then
		self._len = #arg
		self._cdata = gc(cast("unsigned char*", C.calloc(self._len, 1)), C.free)
		ffi_copy(self._cdata, arg, self._len)
	end
end

function Buffer:__tostring()
	return ffi_string(self._cdata, self._len)
end

function Buffer:__len()
	return self._len
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

local function readUInt8(self, k)
	return get(self, k)
end

local function readUInt16LE(self, k)
	return get(self, k) + lshift(get(self, k + 1), 8)
end

local function readUInt16BE(self, k)
	return lshift(get(self, k), 8) + get(self, k + 1)
end

local function readUInt32LE(self, k)
	return get(self, k) + lshift(get(self, k + 1), 8) + lshift(get(self, k + 2), 16) + get(self, k + 3) * 0x1000000
end

local function readUInt32BE(self, k)
	return get(self, k) * 0x1000000 + lshift(get(self, k + 1), 16) + lshift(get(self, k + 2), 8) + get(self, k + 3)
end

local function readInt8(self, k)
	return complement8(readUInt8(self, k))
end

local function readInt16LE(self, k)
	return complement16(readUInt16LE(self, k))
end

local function readInt16BE(self, k)
	return complement16(readUInt16BE(self, k))
end

local function readInt32LE(self, k)
	tobit(readInt32LE(self, k))
end

local function readInt32BE(self, k)
	tobit(readInt32BE(self, k))
end

local function readString(self, k, len)
	k = k or 0
	len = len or self._len - k
	return ffi_string(self._cdata + k, len)
end

local function writeUInt8(self, k, v)
	set(self, k, rshift(v, 0))
end

local function writeUInt16LE(self, k, v)
	set(self, k, rshift(v, 0))
	set(self, k + 1, rshift(v, 8))
end

local function writeUInt16BE(self, k, v)
	set(self, k, rshift(v, 8))
	set(self, k + 1, rshift(v, 0))
end

local function writeUInt32LE(self, k, v)
	set(self, k, rshift(v, 0))
	set(self, k + 1, rshift(v, 8))
	set(self, k + 2, rshift(v, 16))
	set(self, k + 3, rshift(v, 24))
end

local function writeUInt32BE(self, k, v)
	set(self, k, rshift(v, 24))
	set(self, k + 1, rshift(v, 16))
	set(self, k + 2, rshift(v, 8))
	set(self, k + 3, rshift(v, 0))
end

local function writeString(self, k, str, len)
	k = k or 0
	len = len or #str
	ffi_copy(self._cdata + k, str, len)
end

local function toString(self, i, j)
	i = i or 0
	j = j or self._len
	return ffi_string(self._cdata + i, j - i)
end

local function toHex(self, i, j)
	local str = {}
	i = i or 0
	j = j or self._len
	for n = i, j - 1 do
		str[n + 1] = tohex(get(self, n), 2)
	end
	return concat(str, ' ')
end

local function copy(self, target, targetStart, sourceStart, sourceEnd)
	targetStart = targetStart or 0
	sourceStart = sourceStart or 0
	sourceEnd = sourceEnd or self._len
	local len = sourceEnd - sourceStart
	ffi_copy(target._cdata + targetStart, self._cdata + sourceStart, len)
end

method('readUInt8', readUInt8, 'offset', 'Reads an unsigned 8-bit integer from the buffer')
method('readUInt16LE', readUInt16LE, 'offset', 'Reads an unsigned 16-bit little-endian integer from the buffer')
method('readUInt16BE', readUInt16BE, 'offset', 'Reads an unsigned 16-bit big-endian integer from the buffer')
method('readUInt32LE', readUInt32LE, 'offset', 'Reads an unsigned 32-bit little-endian integer from the buffer')
method('readUInt32BE', readUInt32BE, 'offset', 'Reads an unsigned 32-bit big-endian integer from the buffer')
method('readInt8', readInt8, 'offset', 'Reads a signed 8-bit integer from the buffer')
method('readInt16LE', readInt16LE, 'offset', 'Reads a signed 16-bit little-endian integer from the buffer')
method('readInt16BE', readInt16BE, 'offset', 'Reads a signed 16-bit big-endian integer from the buffer')
method('readInt32LE', readInt32LE, 'offset', 'Reads a signed 32-bit little-endian integer from the buffer')
method('readInt32BE', readInt32BE, 'offset', 'Reads a signed 32-bit big-endian integer from the buffer')
method('readString', readString, '[offset, len]', 'Reads a Lua string from the buffer')

method('writeUInt8', writeUInt8, 'offset', 'Writes an unsigned 8-bit integer to the buffer')
method('writeUInt16LE', writeUInt16LE, 'offset', 'Writes an unsigned 16-bit little-endian integer to the buffer')
method('writeUInt16BE', writeUInt16BE, 'offset', 'Writes an unsigned 16-bit big-endian integer to the buffer')
method('writeUInt32LE', writeUInt32LE, 'offset', 'Writes an unsigned 32-bit little-endian integer to the buffer')
method('writeUInt32BE', writeUInt32BE, 'offset', 'Writes an unsigned 32-bit big-endian integer to the buffer')
method('writeInt8', writeUInt8, 'offset', 'Writes an unsigned 8-bit integer to the buffer')
method('writeInt16LE', writeUInt16LE, 'offset', 'Writes a signed 16-bit little-endian integer to the buffer')
method('writeInt16BE', writeUInt16BE, 'offset', 'Writes a signed 16-bit big-endian integer to the buffer')
method('writeInt32LE', writeUInt32LE, 'offset', 'Writes a signed 32-bit little-endian integer to the buffer')
method('writeInt32BE', writeUInt32BE, 'offset', 'Writes a signed 32-bit big-endian integer to the buffer')
method('writeString', writeString, 'offset, string[, len]', 'Writes a Lua string to the buffer')

method('toString', toString, '[i, j]', 'Returns a slice of the buffer as a raw string')
method('toHex', toHex, '[i, j]', 'Returns a slice of the buffer as a hex string')
method('copy', copy, 'target[, targetStart, sourceStart, sourceEnd]', 'Copies a slice of the buffer into another buffer')

return Buffer
