-- a re-write of Luvit's built-in event emitter
-- not 100% compatable, though it can be made to be
-- event callbacks are made coroutines by default

local wrap, yield = coroutine.wrap, coroutine.yield
local insert, remove = table.insert, table.remove
local process = process -- luacheck: ignore process

local Emitter, _, method = class('Emitter')
Emitter.__description = "Modified version of Luvit's built-in event emitter. Automatically wraps event callbacks with coroutines."

function Emitter:__init()
	self._listeners = {}
end

local function missingHandlerType(self, name, ...)
	if name ~= 'error' then return end
	if self == process then return end
	local handlers = rawget(process, 'handlers')
	if handlers and handlers['error'] then
		return process:emit('error', ..., self)
	end
end

local function once(self, name, listener)
	local listeners = self._listeners[name] or {}
	self._listeners[name] = listeners
	local function wrapper(...)
		self:removeListener(name, wrapper)
		return listener(...)
	end
	insert(listeners, wrapper)
	return listener
end

local function on(self, name, listener)
	local listeners = self._listeners[name] or {}
	self._listeners[name] = listeners
	insert(listeners, listener)
	return listener
end

local function getListenerCount(self, name)
	local listeners = self._listeners[name]
	if not listeners then return 0 end
	local n = 0
	for _, listener in ipairs(listeners) do
		if listener then
			n = n + 1
		end
	end
	return n
end

local function emit(self, name, ...)
	local listeners = self._listeners[name]
	if not listeners then
		return missingHandlerType(self, name, ...)
	end
	for _, listener in ipairs(listeners) do
		if listener then
			wrap(listener)(...)
		end
	end
	if self._flagged then
		for i = #listeners, 1, -1 do
			if not listeners[i] then
				remove(listeners, i)
			end
		end
		if #listeners == 0 then
			self._listeners[name] = nil
		end
		self._flagged = nil
	end
end

local function removeListener(self, name, listener)
	local listeners = self._listeners[name]
	if not listeners then return end
	for i, v in ipairs(listeners) do
		if v == listener then
			listeners[i] = false
			self._flagged = true
			break
		end
	end
end

local function removeAllListeners(self, name)
	 self._listeners[name] = nil
end

local function getListeners(self, name)
	local listeners = self._listeners[name]
	if not listeners then return function() end end
	return wrap(function()
		for _, listener in ipairs(listeners) do
			if listener then
				yield(listener)
			end
		end
	end)
end

local function propagate(self, name, target)
	if target and target.emit then
		self:on(name, function(...) target:emit(name, ...) end)
		return target
	end
	return self
end

method('once', once, 'name, listener', "Registers a listener function that is called once and unregistered when a named event is emitted.")
method('on', on, 'name, listener', "Registers a listener function that is called every time a named event is emitted.")
method('getListenerCount', getListenerCount, 'name', "Returns the number of listeners that are registered to a named event.")
method('emit', emit, 'name[, ...]', "Emits a named event with an optional variable amount of arguments.")
method('removeListener', removeListener, 'name, listener', "Unregisters a listener from a named event.")
method('removeAllListeners', removeAllListeners, 'name', "Unregisters all listeners from a named event.")
method('getListeners', getListeners, 'name', "Returns a iterator for the listeners registered to a named event.")
method('propagate', propagate, 'name, target', "Causes all named event emissions to propagates to another target emitter.")

return Emitter
