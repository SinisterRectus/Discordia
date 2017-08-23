local timer = require('timer')

local wrap, yield = coroutine.wrap, coroutine.yield
local resume, running = coroutine.resume, coroutine.running
local insert, remove = table.insert, table.remove
local setTimeout, clearTimeout = timer.setTimeout, timer.clearTimeout

local listenersMeta = {
	__index = function(self, k)
		self[k] = {}
		return self[k]
	end
}

local Emitter = require('class')('Emitter')

--[[
@class Emitter

Implements an asynchronous event emitter where callbacks can be subscribed to
specific named events. When events are emitted, the callbacks are called in the
order that they were originally registered.
]]
function Emitter:__init()
	self._listeners = setmetatable({}, listenersMeta)
end

--[[
@method on
@param name: string
@param  fn: function
@ret function

Subscribes a callback to be called every time the named event is emitted.
Callbacks registered with this method will automatically be wrapped as a new
coroutine when they are called. Returns the original callback for convenience.
]]
function Emitter:on(name, fn)
	insert(self._listeners[name], {fn = fn})
	return fn
end

--[[
@method once
@param name: string
@param  fn: function
@ret function

Subscribes a callback to be called only the first time this event is emitted.
Callbacks registered with this method will automatically be wrapped as a new
coroutine when they are called. Returns the original callback for convenience.
]]
function Emitter:once(name, fn)
	insert(self._listeners[name], {fn = fn, once = true})
	return fn
end

--[[
@method onSync
@param name: string
@param  fn: function
@ret function

Subscribes a callback to be called every time the named event is emitted.
Callbacks registered with this method are not automatically wrapped as a
coroutine. Returns the original callback for convenience.
]]
function Emitter:onSync(name, fn)
	insert(self._listeners[name], {fn = fn, sync = true})
	return fn
end

--[[
@method onceSync
@param name: string
@param  fn: function
@ret function

Subscribes a callback to be called only the first time this event is emitted.
Callbacks registered with this method are not automatically wrapped as a
coroutine. Returns the original callback for convenience.
]]
function Emitter:onceSync(name, fn)
	insert(self._listeners[name], {fn = fn, once = true, sync = true})
	return fn
end

--[[
@method emit
@param name: string
@param [...]: *

Emits the named event and a variable number of arguments to pass to the event
callbacks.
]]
function Emitter:emit(name, ...)
	local listeners = self._listeners[name]
	for i = 1, #listeners do
		local listener = listeners[i]
		if listener then
			local fn = listener.fn
			if listener.once then
				self:removeListener(name, fn)
			end
			if listener.sync then
				fn(...)
			else
				wrap(fn)(...)
			end
		end
	end
	if listeners._removed then
		for i = #listeners, 1, -1 do
			if not listeners[i] then
				remove(listeners, i)
			end
		end
		listeners._removed = nil
	end
end

--[[
@method getListeners
@param name: string
@ret function

Returns an iterator for all callbacks registered to the named event.
]]
function Emitter:getListeners(name)
	local listeners = self._listeners[name]
	return wrap(function()
		for _, listener in ipairs(listeners) do
			if listener then
				yield(listener.fn)
			end
		end
	end)
end

--[[
@method getListenerCount
@param name: string
@ret number

Returns the number of callbacks registered to the named event.
]]
function Emitter:getListenerCount(name)
	local listeners = self._listeners[name]
	local n = 0
	for _, listener in ipairs(listeners) do
		if listener then
			n = n + 1
		end
	end
	return n
end

--[[
@method removeListener
@param name: string
@param fn: function

Unregisters all instances of the callback from the named event.
]]
function Emitter:removeListener(name, fn)
	local listeners = self._listeners[name]
	for i, listener in ipairs(listeners) do
		if listener and listener.fn == fn then
			listeners[i] = false
		end
	end
	listeners._removed = true
end

--[[
@method removeAllListeners
@param name: string

Unregisters all callbacks from the named event.
]]
function Emitter:removeAllListeners(name)
	self._listeners[name] = nil
end

--[[
@method waitFor
@param name: string
@param [timeout]: number
@ret boolean, ...

When called inside of a coroutine, this will yield the coroutine until the
specific named event is emitted or until a timeout (in milliseconds) expires.
If the coroutine is resumed by the event, then `true` is returned with any event
arguments. If the coroutine is resumed by the timeout's expiration, then `false`
is returned without any other arguments.
]]
function Emitter:waitFor(name, timeout)
	local thread = running()
	local fn = self:onceSync(name, function(...)
		if timeout then
			clearTimeout(timeout)
		end
		return assert(resume(thread, true, ...))
	end)
	timeout = timeout and setTimeout(timeout, function()
		self:removeListener(name, fn)
		return assert(resume(thread, false))
	end)
	return yield()
end

return Emitter
