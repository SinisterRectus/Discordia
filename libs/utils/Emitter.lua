local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local wrap, yield, running = coroutine.wrap, coroutine.yield, coroutine.running
local insert, remove = table.insert, table.remove
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

function meta:__call(eventName, callback, errorHandler, once)
	local listener = {
		eventName = checkType('string', eventName),
		callback = checkCallable(callback),
		errorHandler = errorHandler and checkCallable(errorHandler),
		once = once,
	}
	table.insert(self[listener.eventName], listener)
	return listener.callback
end

local function mark(listeners, i)
	listeners[i] = false
	listeners.marked = true
end

local function clean(listeners)
	for i = #listeners, 1, -1 do
		if not listeners[i] then
			remove(listeners, i)
		end
	end
	listeners.marked = nil
end

function Emitter:__init()
	self._listeners = setmetatable({}, meta)
end

function Emitter:on(eventName, callback, errorHandler)
	return self._listeners(eventName, callback, errorHandler)
end

function Emitter:once(eventName, callback, errorHandler)
	return self._listeners(eventName, callback, errorHandler, true)
end

function Emitter:emit(eventName, ...)
	local listeners = self._listeners[checkType('string', eventName)]
	for i = 1, #listeners do
		local listener = listeners[i]
		if listener then
			if listener.once then
				mark(listeners, i)
			end
			if listener.errorHandler then
				local success, err = pcall(wrap(listener.callback), ...)
				if not success then
					wrap(listener.errorHandler)(err, ...)
				end
			else
				wrap(listener.callback)(...)
			end
		end
	end
	if listeners.marked then
		clean(listeners)
	end
end

function Emitter:getListeners(eventName)
	local listeners = self._listeners[checkType('string', eventName)]
	local new = {}
	for _, v in ipairs(listeners) do
		if v then
			insert(new, v.callback)
		end
	end
	return new
end

function Emitter:removeListener(eventName, callback)
	local listeners = self._listeners[checkType('string', eventName)]
	checkCallable(callback)
	for i, v in ipairs(listeners) do
		if v and v.callback == callback then
			mark(listeners, i)
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
	local thread = running()

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

	return yield()

end

return Emitter