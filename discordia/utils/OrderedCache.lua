local Cache = require('./Cache')
local OrderedCache = class('OrderedCache', Cache)

function OrderedCache:__init(array, constructor, key, max, parent)
	Cache.__init(self, array, constructor, key, parent)
	self.max = max
	self.next = {}
	self.prev = {}
end

function OrderedCache:add(obj) -- push from the right
	if Cache.add(self, obj) then
		if self.count == 1 then
			self.first = obj
			self.last = obj
		else
			self.next[self.last] = obj
			self.prev[obj] = self.last
			self.last = obj
		end
		if self.count > self.max then self:remove(self.first) end
		return true
	else
		return false
	end
end

function OrderedCache:remove(obj)
	if Cache.remove(self, obj) then
		if self.count == 0 then
			self.first = nil
			self.last = nil
		else
			local prev = self.prev[obj]
			local next = self.next[obj]
			if obj == self.last then
				self.last = prev
				self.next[prev] = nil
			elseif obj == self.first then
				self.first = next
				self.prev[next] = nil
			else
				self.next[prev] = next
				self.prev[next] = prev
			end
		end
		return true
	else
		return false
	end
end

function OrderedCache:filter(predicate)
	local cache = OrderedCache({}, self.constructor, self.key, self.max, self.parent)
	for obj in self:iter() do
		if predicate(obj) then
			cache:add(obj)
		end
	end
	return cache
end

function OrderedCache:iterLastToFirst()
	local obj = self.last
	return function()
		local ret = obj
		obj = obj and self.prev[obj] or nil
		return ret
	end
end

function OrderedCache:iterFirstToLast()
	local obj = self.first
	return function()
		local ret = obj
		obj = obj and self.next[obj] or nil
		return ret
	end
end

function OrderedCache:iter(reverse)
	return reverse and self:iterLastToFirst() or self:iterFirstToLast()
end

return OrderedCache
