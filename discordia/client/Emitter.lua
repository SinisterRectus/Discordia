-- a re-write of Luvit's built-in event emitter
-- not 100% compatable, though it can be made to be
-- event callbacks are made coroutines by default

local wrap = coroutine.wrap
local insert, remove = table.insert, table.remove

local Emitter = class('Emitter')

function Emitter:__init()
	self._listeners = {}
end

local function missingHandlerType(self, name, ...)
	if name ~= 'error' then return end
	if self == process then return end
	local handlers = rawget(process, 'handlers')
	if handlers and handlers['error'] then
		process:emit('error', ..., self)
	end
end

function Emitter:once(name, listener)
	local listeners = self._listeners[name] or {}
	self._listeners[name] = listeners
	local function wrapper(...)
		self:removeListener(name, wrapper)
		return listener(...)
	end
	insert(listeners, wrapper)
end

function Emitter:on(name, listener)
	local listeners = self._listeners[name] or {}
	self._listeners[name] = listeners
	insert(listeners, listener)
end

function Emitter:listenerCount(name)
	local listeners = self._listeners[name]
	return listeners and #listeners or 0
end

function Emitter:emit(name, ...)
	local listeners = self._listeners[name]
	if not listeners then
		return missingHandlerType(self, name, ...)
	end
	local i, n = 1, #listeners
	while i <= n do
		wrap(listeners[i])(...)
		if #listeners == n then
			i = i + 1
		else
			n = #listeners
		end
	end
end

function Emitter:removeListener(name, listener)
	local listeners = self._listeners[name]
	if not listeners then return end
	for i = 1, #listeners do
		if listeners[i] == listener then
			remove(listeners, i)
			break
		end
	end
end

function Emitter:removeAllListeners(name)
	 self._listeners[name] = nil
end

function Emitter:listeners(name)
	return self._listeners[name] or {}
end

function Emitter:propagate(name, target)
	if target and target.emit then
		self:on(name, function(...) target:emit(name, ...) end)
		return target
	end
	return self
end

return Emitter
