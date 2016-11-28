local Buffer, property, method = class('Buffer')
Buffer.__description = "Modified version of Luvit's low-level buffer class."

local ffi = require('ffi')

local concat = table.concat
local gc, cast = ffi.gc, ffi.cast
local lshift, rshift, tohex = bit.lshift, bit.rshift, bit.tohex

ffi.cdef[[
	void *malloc(size_t size);
	void *calloc(size_t num, size_t size);
	void *realloc(void *ptr, size_t size);
	void free(void *ptr);
]]

local C = ffi.os == 'Windows' and ffi.load('msvcrt') or ffi.C

function Buffer:__init(len)
	self._len = len
	self._cdata = gc(cast('unsigned char*', C.calloc(len, 1)), C.free)
end

function Buffer:__tostring()
	return ffi.string(self._cdata, self._len)
end

local rawindex = Buffer.__index
function Buffer:__index(k)
	if type(k) == 'number' then
		if k < 0 or k > self._len then
			return error('buffer index out of bounds')
		end
		return self._cdata[k]
	end
	return rawindex(self, k)
end

local rawnewindex = Buffer.__newindex
function Buffer:__newindex(k, v)
	if type(k) == 'number' then
		if k < 0 or k > self._len then
			return error('buffer index out of bounds')
		end
		self._cdata[k] = v
		return
	end
	return rawnewindex(self, k, v)
end

function Buffer:__ipairs()
	local i = -1
	local len = self._len
	local cdata = self._cdata
	return function()
		if i < len then
			i = i + 1
			return i, cdata[i]
		end
	end
end

local function readUInt8(self, k)
	return self[k]
end

local function readUInt16LE(self, k)
	return self[k] + lshift(self[k + 1], 8)
end

local function readUInt16BE(self, k)
	return lshift(self[k], 8) + self[k + 1]
end

local function readUInt32LE(self, k)
	return self[k] + lshift(self[k + 1], 8) + lshift(self[k + 2], 16) + self[k + 3] * 0x1000000
end

local function readUInt32BE(self, k)
	return self[k] * 0x1000000 + lshift(self[k + 1], 16) + lshift(self[k + 2], 8) + self[k + 3]
end

local function writeUInt8(self, k, v)
	self[k] = v
end

local function writeUInt16LE(self, k, v)
	self[k] = v
	self[k + 1] = rshift(v, 8)
end

local function writeUInt16BE(self, k, v)
	self[k] = rshift(v, 8)
	self[k + 1] = v
end

local function writeUInt32LE(self, k, v)
	self[k] = v
	self[k + 1] = rshift(v, 8)
	self[k + 2] = rshift(v, 16)
	self[k + 3] = rshift(v, 24)
end

local function writeUInt32BE(self, k, v)
	self[k] = rshift(v, 24)
	self[k + 1] = rshift(v, 16)
	self[k + 2] = rshift(v, 8)
	self[k + 3] = v
end

local function toString(self, i, j)
	i = i or 0
	j = j or self._len
	return ffi.string(self._cdata + i, j - i)
end

local function toHex(self, i, j)
	local str = {}
	i = i or 0
	j = j or self._len
	for n = i, j - 1 do
		str[n + 1] = tohex(self[n], 2)
	end
	return concat(str, ' ')
end

property('length', '_len', nil, 'number', 'Pre-determined length of the buffer')

method('readUInt8', readUInt8, 'offset', 'Reads an unsigned 8-bit integer from the buffer')
method('readUInt16LE', readUInt16LE, 'offset', 'Reads an unsigned 16-bit little-endian integer from the buffer')
method('readUInt16BE', readUInt16BE, 'offset', 'Reads an unsigned 16-bit big-endian integer from the buffer')
method('readUInt32LE', readUInt32LE, 'offset', 'Reads an unsigned 32-bit little-endian integer from the buffer')
method('readUInt32BE', readUInt32BE, 'offset', 'Reads an unsigned 32-bit big-endian integer from the buffer')

method('writeUInt8', writeUInt8, 'offset', 'Writes an unsigned 8-bit integer to the buffer')
method('writeUInt16LE', writeUInt16LE, 'offset', 'Writes an unsigned 16-bit little-endian integer to the buffer')
method('writeUInt16BE', writeUInt16BE, 'offset', 'Writes an unsigned 16-bit big-endian integer to the buffer')
method('writeUInt32LE', writeUInt32LE, 'offset', 'Writes an unsigned 32-bit little-endian integer to the buffer')
method('writeUInt32BE', writeUInt32BE, 'offset', 'Writes an unsigned 32-bit big-endian integer to the buffer')

method('toString', toString, '[i, j]', 'Returns a slice of the buffer as a raw string')
method('toHex', toHex, '[i, j]', 'Returns a slice of the buffer as a hex string')

return Buffer
