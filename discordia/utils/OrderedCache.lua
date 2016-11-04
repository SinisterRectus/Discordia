local Cache = require('./Cache')

local OrderedCache, property, method = class('OrderedCache', Cache)
OrderedCache.__description = "Extention of Cache that maintains object order using a linked list. If the ordered cache is full, adding a new object will discard the oldest object."

function OrderedCache:__init(array, constructor, key, limit, parent)
	Cache.__init(self, array, constructor, key, parent)
	self._limit = limit
	self._next = {}
	self._prev = {}
end

function OrderedCache:_add(obj)
	local key = self._key
	if self._count == 0 then
		self._first = obj
		self._last = obj
	else
		self._next[self._last[key]] = obj
		self._prev[obj[key]] = self._last
		self._last = obj
	end
	if self._count == self._limit then self:remove(self._first) end
	self._objects[obj[key]] = obj
	self._count = self._count + 1
end

function OrderedCache:_remove(obj)
	local key = self._key
	if self._count == 1 then
		self._first = nil
		self._last = nil
	else
		local prev = self._prev[obj[key]]
		local next = self._next[obj[key]]
		if obj == self._last then
			self._last = prev
			self._next[prev[key]] = nil
		elseif obj == self._first then
			self._first = next
			self._prev[next[key]] = nil
		else
			self._next[prev[key]] = next
			self._prev[next[key]] = prev
		end
	end
	self._objects[obj[key]] = nil
	self._count = self._count - 1
end

local function iterLastToFirst(self)
	local obj = self._last
	local key = self._key
	return function()
		local ret = obj
		obj = obj and self._prev[obj[key]] or nil
		return ret
	end
end

local function iterFirstToLast(self)
	local obj = self._first
	local key = self._key
	return function()
		local ret = obj
		obj = obj and self._next[obj[key]] or nil
		return ret
	end
end

local function iter(self, reverse)
	return reverse and self:iterLastToFirst() or self:iterFirstToLast()
end

property('limit', '_limit', nil, 'number', "The maximum amount of objects that can be cached before the cache starts to empty")
property('first', '_first', nil, '*', "The first, or oldest, object in the cache")
property('last', '_last', nil, '*', "The last, or newest, object in the cache")

method('iterLastToFirst', iterLastToFirst, nil, "Returns an iterator for the objects in order of last (newest) to first (oldest).")
method('iterFirstToLast', iterFirstToLast, nil, "Returns an iterator for the objects in order of first (oldest) to last (newest).")
method('iter', iter, '[reverse]', "Equivalent to `iterFirstToLast` (or `iterLastToFirst` if reverse is `true`).")

return OrderedCache
