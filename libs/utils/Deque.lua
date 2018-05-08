--[=[@c Deque desc]=]

local Deque = require('class')('Deque')

function Deque:__init()
	self._objects = {}
	self._first = 0
	self._last = -1
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:getCount()
	return self._last - self._first + 1
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:pushLeft(obj)
	self._first = self._first - 1
	self._objects[self._first] = obj
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:pushRight(obj)
	self._last = self._last + 1
	self._objects[self._last] = obj
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:popLeft()
	if self._first > self._last then return nil end
	local obj = self._objects[self._first]
	self._objects[self._first] = nil
	self._first = self._first + 1
	return obj
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:popRight()
	if self._first > self._last then return nil end
	local obj = self._objects[self._last]
	self._objects[self._last] = nil
	self._last = self._last - 1
	return obj
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:peekLeft()
	return self._objects[self._first]
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:peekRight()
	return self._objects[self._last]
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Deque:iter()
	local t = self._objects
	local i = self._first - 1
	return function()
		i = i + 1
		return t[i]
	end
end

return Deque
