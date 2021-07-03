local class = require('../class')
local typing = require('../typing')

local wrap = coroutine.wrap
local checkType = typing.checkType
local checkCallable = typing.checkCallable

local Listener, get = class('Listener')

function Listener:__init(emitter, eventName, callback, errorHandler)
	self._emitter = assert(emitter)
	self._eventName = checkType('string', eventName)
	self._callback = checkCallable(callback)
	self._errorHandler = errorHandler and checkCallable(errorHandler)
	self._enabled = true
end

function Listener:fire(...)
	if self.errorHandler then
		local success, err = pcall(wrap(self.callback), ...)
		if not success then
			wrap(self.errorHandler)(err, ...)
		end
	else
		wrap(self.callback)(...)
	end
end

function Listener:unregister()
	return self.emitter:removeListener(self.eventName, self)
end

function get:emitter()
	return self._emitter
end

function get:eventName()
	return self._eventName
end

function get:callback()
	return self._callback
end

function get:errorHandler()
	return self._errorHandler
end

function get:enabled()
	return self._enabled
end

return Listener
