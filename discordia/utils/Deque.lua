local Deque, property, method = class('Deque')
Deque.__description = "Implementation of a double-ended queue."

function Deque:__init()
	self._objects = {}
	self._first = 0
	self._last = -1
end

local function getCount(self)
	return self._last - self._first + 1
end

local function pushLeft(self, obj)
	self._first = self._first - 1
	self._objects[self._first] = obj
end

local function pushRight(self, obj)
	self._last = self._last + 1
	self._objects[self._last] = obj
end

local function popLeft(self)
	if self._first > self._last then return nil end
	local obj = self._objects[self._first]
	self._objects[self._first] = nil
	self._first = self._first + 1
	return obj
end

local function popRight(self)
	if self._first > self._last then return nil end
	local obj = self._objects[self._last]
	self._objects[self._last] = nil
	self._last = self._last - 1
	return obj
end

local function peekLeft(self)
	return self._objects[self._first]
end

local function peekRight(self)
	return self._objects[self._last]
end

local function iter(self)
	local t = self._objects
	local i, n = self._first, self._last
	return function()
		if i > n then return end
		local v = t[i]; i = i + 1
		return v
	end
end

property('count', getCount, nil, 'number', "How many objects are in the deque")

method('pushLeft', pushLeft, 'obj', "Push an object to the left side of the deque.")
method('pushRight', pushRight, 'obj', "Push an object to the right side of the deque.")
method('popLeft', popLeft, nil, "Pop an object from the left side of the deque and return it.")
method('popRight', popRight, nil, "Pop and object from the right side of the deque and return it.")
method('peekLeft', peekLeft, nil, "Returns the object at the left side of the deque, but does not pop it.")
method('peekRight', peekRight, nil, "Returns the object at the right side of the deque, but does not pop it.")
method('iter', iter, nil, "Returns an iterator for the objects in the deque, from left to right.")

return Deque
