--[=[@c Emitter ...]=]

local timer = require('timer')

local wrap, yield = coroutine.wrap, coroutine.yield
local resume, running = coroutine.resume, coroutine.running
local insert, remove = table.insert, table.remove
local setTimeout, clearTimeout = timer.setTimeout, timer.clearTimeout

local Emitter = require('class')('Emitter')

function Emitter:__init()
	self._listeners = {}
end

local function new(self, name, listener)
	local listeners = self._listeners[name]
	if not listeners then
		listeners = {}
		self._listeners[name] = listeners
	end
	insert(listeners, listener)
	return listener.fn
end

--[=[
@m on
@p name string
@p fn function
@r function
@d ...
]=]
function Emitter:on(name, fn)
	return new(self, name, {fn = fn})
end

--[=[
@m once
@p name string
@p fn function
@r function
@d ...
]=]
function Emitter:once(name, fn)
	return new(self, name, {fn = fn, once = true})
end

--[=[
@m onSync
@p name string
@p fn function
@r function
@d ...
]=]
function Emitter:onSync(name, fn)
	return new(self, name, {fn = fn, sync = true})
end

--[=[
@m onceSync
@p name string
@p fn function
@r function
@d ...
]=]
function Emitter:onceSync(name, fn)
	return new(self, name, {fn = fn, once = true, sync = true})
end

--[=[
@m emit
@p name string
@p ... *
@r void
@d ...
]=]
function Emitter:emit(name, ...)
	local listeners = self._listeners[name]
	if not listeners then return end
	for i = 1, #listeners do
		local listener = listeners[i]
		if listener then
			local fn = listener.fn
			if listener.once then
				listeners[i] = false
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
		if #listeners == 0 then
			self._listeners[name] = nil
		end
		listeners._removed = nil
	end
end

--[=[
@m getListeners
@p name string
@r function
@d ...
]=]
function Emitter:getListeners(name)
	local listeners = self._listeners[name]
	if not listeners then return function() end end
	return wrap(function()
		for _, listener in ipairs(listeners) do
			if listener then
				yield(listener.fn)
			end
		end
	end)
end

--[=[
@m getListenerCount
@p name string
@r number
@d ...
]=]
function Emitter:getListenerCount(name)
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

--[=[
@m removeListener
@p name string
@r void
@d ...
]=]
function Emitter:removeListener(name, fn)
	local listeners = self._listeners[name]
	if not listeners then return end
	for i, listener in ipairs(listeners) do
		if listener and listener.fn == fn then
			listeners[i] = false
		end
	end
	listeners._removed = true
end

--[=[
@m removeAllListeners
@p name string
@r void
@d ...
]=]
function Emitter:removeAllListeners(name)
	self._listeners[name] = nil
end

--[=[
@m waitFor
@p name string
@op timeout number
@op predicate function
@r boolean
@r ...
@d ...
]=]
function Emitter:waitFor(name, timeout, predicate)
	local thread = running()
	local fn = self:onceSync(name, function(...)
		if predicate and not predicate(...) then return end
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
