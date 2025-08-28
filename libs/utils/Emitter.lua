local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local setTimeout, clearTimer = helpers.setTimeout, helpers.clearTimer
local checkType = typing.checkType
local checkNumber = typing.checkNumber
local checkCallable = typing.checkCallable
local assertResume = helpers.assertResume

local Emitter = class('Emitter')

local meta = {}

function meta:__index(k)
	self[k] = {}
	return self[k]
end

function meta:__call(eventName, callback, once)
	local listener = {
		eventName = checkType('string', eventName),
		callback = checkCallable(callback),
		once = once,
	}
	table.insert(self[listener.eventName], listener)
	return listener.callback
end

function Emitter:__init()
	self._listeners = setmetatable({}, meta)
end

function Emitter:on(eventName, callback)
	return self._listeners(eventName, callback)
end

function Emitter:once(eventName, callback)
	return self._listeners(eventName, callback, true)
end

function Emitter:emit(eventName, ...)
	local listeners = self._listeners[checkType('string', eventName)]
	local copy = {}
	local i = 1
	while listeners[i] do
		table.insert(copy, listeners[i])
		if listeners[i].once then
			table.remove(listeners, i)
		else
			i = i + 1
		end
	end
	for _, listener in ipairs(copy) do
		listener.callback(...)
	end
end

function Emitter:getListeners(eventName)
	local listeners = self._listeners[checkType('string', eventName)]
	local new = {}
	for _, v in ipairs(listeners) do
		table.insert(new, v.callback)
	end
	return new
end

function Emitter:removeListener(eventName, callback)
	local listeners = self._listeners[checkType('string', eventName)]
	checkCallable(callback)
	for i, v in ipairs(listeners) do
		if v.callback == callback then
			table.remove(listeners, i)
			return true
		end
	end
	return false
end

function Emitter:removeAllListeners(eventName)
	if eventName then
		self._listeners[checkType('string', eventName)] = nil
	else
		for k in pairs(self._listeners) do
			self._listeners[k] = nil
		end
	end
end

function Emitter:waitFor(eventName, timeout, predicate)

	eventName = checkType('string', eventName)
	predicate = predicate and checkCallable(predicate)

	local t, listener
	local thread = coroutine.running()

	local function complete(success, ...)
		if t then
			clearTimer(t)
			t = nil
		end
		if listener then
			self:removeListener(eventName, listener)
			listener = nil
			return assertResume(thread, success, ...)
		end
	end

	listener = self:on(eventName, function(...)
		if not predicate or predicate(...) then
			return complete(true, ...)
		end
	end)

	if timeout then
		t = setTimeout(checkNumber(timeout, 10, 0), complete, false)
	end

	return coroutine.yield()

end

return Emitter