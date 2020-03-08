local timer = require('timer')
local class = require('../class')

local wrap, yield = coroutine.wrap, coroutine.yield
local resume, running = coroutine.resume, coroutine.running
local insert, remove = table.insert, table.remove
local setTimeout, clearTimeout = timer.setTimeout, timer.clearTimeout

local Emitter = class('Emitter')

local meta = {
	__index = function(self, k)
		self[k] = {}
		return self[k]
	end
}

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

function Emitter:on(name, fn, err)
	insert(self._listeners[name], {fn = fn, err = err})
	return fn
end

function Emitter:once(name, fn, err)
	insert(self._listeners[name], {fn = fn, err = err, once = true})
	return fn
end

function Emitter:emit(name, ...)
	local listeners = self._listeners[name]
	for i = 1, #listeners do
		local listener = listeners[i]
		if listener then
			if listener.once then
				mark(listeners, i)
			end
			if listener.err then
				local success, err = pcall(wrap(listener.fn), ...)
				if not success then
					wrap(listener.err)(err, ...)
				end
			else
				wrap(listener.fn)(...)
			end
		end
	end
	if listeners.marked then
		clean(listeners)
	end
end

function Emitter:getListeners(name)
	local listeners = self._listeners[name]
	local i = 0
	return function()
		while i < #listeners do
			i = i + 1
			if listeners[i] then
				return listeners[i].fn
			end
		end
	end
end

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

function Emitter:removeListener(name, fn)
	local listeners = self._listeners[name]
	for i, listener in ipairs(listeners) do
		if listener and listener.fn == fn then
			mark(listeners, i)
			break
		end
	end
end

function Emitter:removeAllListeners(name)
	if name then
		self._listeners[name] = nil
	else
		for k in pairs(self._listeners) do
			self._listeners[k] = nil
		end
	end
end

function Emitter:waitFor(name, timeout, predicate)

	local t, fn
	local thread = running()

	local function complete(success, ...)
		if t then
			clearTimeout(t)
			t = nil
		end
		if fn then
			self:removeListener(name, fn)
			fn = nil
			return assert(resume(thread, success, ...))
		end
	end

	fn = self:on(name, function(...)
		if type(predicate) ~= 'function' or predicate(...) then
			return complete(true, ...)
		end
	end)

	if tonumber(timeout) then
		t = setTimeout(timeout, complete, false)
	end

	return yield()

end

return Emitter
