local Cache = require('./Cache')
local OrderedCache = class('OrderedCache', Cache)

function OrderedCache:__init(array, constructor, key, max, parent)
	Cache.__init(self, array, constructor, key, parent)
	self.max = max
	self.next = {}
	self.prev = {}
end

function OrderedCache:add(obj) -- adds to the right/head
	if Cache.add(self, obj) then
		if self.count == 1 then
			self.head = obj
			self.tail = obj
		else
			self.next[self.head] = obj
			self.prev[obj] = self.head
			self.head = obj
		end
		if self.count > self.max then self:remove(self.tail) end
		return true
	else
		return false
	end
end

function OrderedCache:remove(obj)
	if Cache.remove(self, obj) then
		if self.count == 0 then
			self.head = nil
			self.tail = nil
		else
			local prev = self.prev[obj]
			local next = self.next[obj]
			if obj == self.head then
				self.head = prev
				self.next[prev] = nil
			elseif obj == self.tail then
				self.tail = next
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

function OrderedCache:iter() -- iterates right/head/newer to left/tail/older
	local obj = self.head
	return function()
		local ret = obj
		obj = obj and self.prev[obj] or nil
		return ret
	end
end

function OrderedCache:getNewest()
	return self.head
end

function OrderedCache:getOldest()
	return self.tail
end

function OrderedCache:getAll(key, value, ret)
	ret = ret or OrderedCache({}, self.constructor, self.max, self.parent)
	return Cache.getAll(self, key, value, ret)
end

function OrderedCache:findAll(key, predicate, ret)
	ret = ret or OrderedCache({}, self.constructor, self.max, self.parent)
	return Cache.findAll(self, key, predicate, ret)
end

return OrderedCache
