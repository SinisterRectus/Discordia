--[=[@c Emitter desc]=]

local timer = require('timer')

local wrap, yield = coroutine.wrap, coroutine.yield
local resume, running = coroutine.resume, coroutine.running
local insert, remove = table.insert, table.remove
local setTimeout, clearTimeout = timer.setTimeout, timer.clearTimeout

local Emitter = require('class')('Emitter')

function Emitter:__init()
	self._listeners = {}
	return self
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
@m name
@p name type
@r type
@d desc
]=]
function Emitter:on(name, fn)
	return new(self, name, {fn = fn})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Emitter:once(name, fn)
	return new(self, name, {fn = fn, once = true})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Emitter:onSync(name, fn)
	return new(self, name, {fn = fn, sync = true})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function Emitter:onceSync(name, fn)
	return new(self, name, {fn = fn, once = true, sync = true})
end

--[=[
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
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
@m name
@p name type
@r type
@d desc
]=]
function Emitter:removeAllListeners(name)
	self._listeners[name] = nil
end

--[=[
@m name
@p name type
@r type
@d desc
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
