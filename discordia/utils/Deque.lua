local Deque = class('Deque')

function Deque:__init()
	self.objects = {}
	self.first = 0
	self.last = -1
end

function Deque:pushLeft(obj)
	self.first = self.first - 1
	self.objects[self.first] = obj
end

function Deque:pushRight(obj)
	self.last = self.last + 1
	self.objects[self.last] = obj
end

function Deque:popLeft()
	if self.first > self.last then return nil end
	local obj = self.objects[self.first]
	self.objects[self.first] = nil
	self.first = self.first + 1
	return obj
end

function Deque:popRight()
	if self.first > self.last then return nil end
	local obj = self.objects[self.last]
	self.objects[self.last] = nil
	self.last = self.last - 1
	return obj
end

function Deque:peekLeft()
	return self.objects[self.first]
end

function Deque:peekRight()
	return self.objects[self.last]
end

function Deque:getCount()
	return self.last - self.first + 1
end

function Deque:iter()
	local t = self.objects
	local i, limit = self.first, self.last
	return function()
		if i > limit then return nil end
		local v = t[i]; i = i + 1
		return v
	end
end

return Deque
