local uv = require('uv')
local class = require('../class')
local constants = require('../constants')
local Time = require('./Time')

local hrtime = uv.hrtime

local NS_PER_US = constants.NS_PER_US

local Stopwatch, method = class('Stopwatch')

function method:__init(stopped)
	local t = hrtime()
	self._initial = t
	self._final = stopped and t or nil
end

function method:toString()
	return self:getTime():toString()
end

function method:getTime()
	local ns = (self._final or hrtime()) - self._initial
	return Time.fromMicroseconds(ns / NS_PER_US)
end

function method:start()
	if not self._final then return end
	self._initial = self._initial + hrtime() - self._final
	self._final = nil
end

function method:stop()
	if self._final then return end
	self._final = hrtime()
end

function method:reset()
	self._initial = self._final or hrtime()
end

return Stopwatch
