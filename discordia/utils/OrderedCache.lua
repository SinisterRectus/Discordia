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
			self.head = obj
			self.tail = obj
		else
			self.next[self.tail] = obj
			self.prev[obj] = self.tail
			self.tail = obj
		end
		if self.count > self.max then self:remove(self.head) end
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
			if obj == self.tail then
				self.tail = prev
				self.next[prev] = nil
			elseif obj == self.head then
				self.head = next
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

function OrderedCache:iterRightToLeft() -- iterates right/tail/new to left/head/old
	local obj = self.tail
	return function()
		local ret = obj
		obj = obj and self.prev[obj] or nil
		return ret
	end
end

function OrderedCache:iterLeftToRight() -- iterates left/head/old to right/tail/new
	local obj = self.head
	return function()
		local ret = obj
		obj = obj and self.next[obj] or nil
		return ret
	end
end

function OrderedCache:getOldest()
	return self.head
end

function OrderedCache:getNewest()
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

-- alliases --
OrderedCache.iterOldToNew = OrderedCache.iterLeftToRight
OrderedCache.iterNewToOld = OrderedCache.iterRightToLeft
OrderedCache.iterHeadToTail = OrderedCache.iterLeftToRight
OrderedCache.iterTailToHead = OrderedCache.iterRightToLeft

return OrderedCache
