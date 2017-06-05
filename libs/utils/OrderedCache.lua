local Cache = require('utils/Cache')

local OrderedCache = require('class')('OrderedCache', Cache)

-- TODO: account for object limit

function OrderedCache:__init(constructor, parent)
	Cache.__init(self, constructor, parent)
	self._next = {}
	self._prev = {}
end

function OrderedCache:_add(obj)
	if self._count == 0 then
		self._first = obj
		self._last = obj
	else
		self._next[self._last.id] = obj
		self._prev[obj.id] = self._last
		self._last = obj
	end
	return Cache._add(self, obj)
end

function OrderedCache:_remove(obj)
	if self._count == 1 then
		self._first = nil
		self._last = nil
	else
		local prev = self._prev[obj.id]
		local next = self._next[obj.id]
		if obj == self._last then
			self._last = prev
			self._next[prev.id] = nil
		elseif obj == self._first then
			self._first = next
			self._prev[next.id] = nil
		else
			self._next[prev.id] = next
			self._prev[next.id] = prev
		end
	end
	return Cache._remove(self, obj)
end

function OrderedCache:iter(reverse)
	if reverse then
		local obj = self._last
		return function()
			local ret = obj
			obj = obj and self._prev[obj.id] or nil
			return ret
		end
	else
		local obj = self._first
		return function()
			local ret = obj
			obj = obj and self._next[obj.id] or nil
			return ret
		end
	end
end

return OrderedCache
