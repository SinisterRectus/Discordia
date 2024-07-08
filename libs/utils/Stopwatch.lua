local uv = require('uv')
local class = require('../class')
local constants = require('../constants')
local Time = require('./Time')

local hrtime = uv.hrtime
local NS_PER_US = constants.NS_PER_US

local Stopwatch = class('Stopwatch')

function Stopwatch:__init(stopped)
	local t = hrtime()
	self._initial = t
	self._final = stopped and t or nil
end

function Stopwatch:toString()
	return self:getTime():toString()
end

function Stopwatch:getTime()
	local ns = (self._final or hrtime()) - self._initial
	return Time.fromMicroseconds(ns / NS_PER_US)
end

function Stopwatch:start()
	if not self._final then return end
	self._initial = self._initial + hrtime() - self._final
	self._final = nil
end

function Stopwatch:stop()
	if self._final then return end
	self._final = hrtime()
end

function Stopwatch:reset()
	self._initial = self._final or hrtime()
end

return Stopwatch