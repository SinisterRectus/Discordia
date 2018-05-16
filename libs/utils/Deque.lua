--[=[@c Deque ...]=]

local Deque = require('class')('Deque')

function Deque:__init()
	self._objects = {}
	self._first = 0
	self._last = -1
end

--[=[
@m getCount
@r number
@d ...
]=]
function Deque:getCount()
	return self._last - self._first + 1
end

--[=[
@m pushLeft
@p obj *
@r void
@d ...
]=]
function Deque:pushLeft(obj)
	self._first = self._first - 1
	self._objects[self._first] = obj
end

--[=[
@m pushRight
@p obj *
@r void
@d ...
]=]
function Deque:pushRight(obj)
	self._last = self._last + 1
	self._objects[self._last] = obj
end

--[=[
@m popLeft
@r *
@d ...
]=]
function Deque:popLeft()
	if self._first > self._last then return nil end
	local obj = self._objects[self._first]
	self._objects[self._first] = nil
	self._first = self._first + 1
	return obj
end

--[=[
@m popRight
@r *
@d ...
]=]
function Deque:popRight()
	if self._first > self._last then return nil end
	local obj = self._objects[self._last]
	self._objects[self._last] = nil
	self._last = self._last - 1
	return obj
end

--[=[
@m peekLeft
@r *
@d ...
]=]
function Deque:peekLeft()
	return self._objects[self._first]
end

--[=[
@m peekRight
@r *
@d ...
]=]
function Deque:peekRight()
	return self._objects[self._last]
end

--[=[
@m iter
@r function
@d ...
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
