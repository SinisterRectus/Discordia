local Deque = require('class')('Deque')

function Deque:__init()
	self._objects = {}
	self._first = 0
	self._last = -1
end

--[[
@method getCount
@ret number
]]
function Deque:getCount()
	return self._last - self._first + 1
end

--[[
@method pushLeft
@param obj: *
]]
function Deque:pushLeft(obj)
	self._first = self._first - 1
	self._objects[self._first] = obj
end

--[[
@method pushRight
@param obj: *
]]
function Deque:pushRight(obj)
	self._last = self._last + 1
	self._objects[self._last] = obj
end

--[[
@method popLeft
@ret *
]]
function Deque:popLeft()
	if self._first > self._last then return nil end
	local obj = self._objects[self._first]
	self._objects[self._first] = nil
	self._first = self._first + 1
	return obj
end

--[[
@method popRight
@ret *
]]
function Deque:popRight()
	if self._first > self._last then return nil end
	local obj = self._objects[self._last]
	self._objects[self._last] = nil
	self._last = self._last - 1
	return obj
end

--[[
@method peekLeft
@ret *
]]
function Deque:peekLeft()
	return self._objects[self._first]
end

--[[
@method peekRight
@ret *
]]
function Deque:peekRight()
	return self._objects[self._last]
end

--[[
@method iter
@ret function
]]
function Deque:iter()
	local t = self._objects
	local i = self._first - 1
	return function()
		i = i + 1
		return t[i]
	end
end

return Deque
