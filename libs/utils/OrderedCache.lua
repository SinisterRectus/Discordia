local Cache = require('utils/Cache')

local OrderedCache = require('class')('OrderedCache', Cache)

-- TODO: account for object limit

function OrderedCache:__init(constructor, parent)
	Cache.__init(self, constructor, parent)
	self._next = {}
	self._prev = {}
end

function OrderedCache:_insert(k, obj)
	if self._count == 0 then
		self._first = obj
		self._last = obj
	else
		self._next[self._last:__hash()] = obj
		self._prev[k] = self._last
		self._last = obj
	end
	return Cache._insert(self, k, obj)
end

function OrderedCache:_remove(k, obj)
	if self._count == 1 then
		self._first = nil
		self._last = nil
	else
		local prev = self._prev[k]
		local next = self._next[k]
		if obj == self._last then
			self._last = prev
			self._next[prev:__hash()] = nil
		elseif obj == self._first then
			self._first = next
			self._prev[next:__hash()] = nil
		else
			self._next[prev:__hash()] = next
			self._prev[next:__hash()] = prev
		end
	end
	return Cache._remove(self, k, obj)
end

function OrderedCache:iter(reverse)
	if reverse then
		local obj = self._last
		return function()
			local ret = obj
			obj = obj and self._prev[obj:__hash()] or nil
			return ret
		end
	else
		local obj = self._first
		return function()
			local ret = obj
			obj = obj and self._next[obj:__hash()] or nil
			return ret
		end
	end
end

return OrderedCache
