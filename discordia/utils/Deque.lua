local Deque, get = class('Deque')

function Deque:__init()
	self._objects = {}
	self._first = 0
	self._last = -1
end

get('count', function(self)
	return self._last - self._first + 1
end)

function Deque:pushLeft(obj)
	self._first = self._first - 1
	self._objects[self._first] = obj
end

function Deque:pushRight(obj)
	self._last = self._last + 1
	self._objects[self._last] = obj
end

function Deque:popLeft()
	if self._first > self._last then return nil end
	local obj = self._objects[self._first]
	self._objects[self._first] = nil
	self._first = self._first + 1
	return obj
end

function Deque:popRight()
	if self._first > self._last then return nil end
	local obj = self._objects[self._last]
	self._objects[self._last] = nil
	self._last = self._last - 1
	return obj
end

function Deque:peekLeft()
	return self._objects[self._first]
end

function Deque:peekRight()
	return self._objects[self._last]
end

function Deque:iter()
	local t = self._objects
	local i, limit = self._first, self._last
	return function()
		if i > limit then return nil end
		local v = t[i]; i = i + 1
		return v
	end
end

return Deque
