local Deque = class('Deque')

function Deque:__init()
	self.list = {}
	self.first = 0
	self.last = -1
end

function Deque:pushLeft(value)
	self.first = self.first - 1
	self.list[self.first] = value
end

function Deque:pushRight(value)
	self.last = self.last + 1
	self.list[self.last] = value
end

function Deque:popLeft()
	if self.first > self.last then return nil end
	local value = self.list[self.first]
	self.list[self.first] = nil
	self.first = self.first + 1
	return value
end

function Deque:popRight()
	if self.first > self.last then return nil end
	local value = self.list[self.last]
	self.list[self.last] = nil
	self.last = self.last - 1
	return value
end

function Deque:peekLeft()
	return self.list[self.first]
end

function Deque:peekRight()
	return self.list[self.last]
end

function Deque:getCount()
	return self.last - self.first + 1
end

return Deque
