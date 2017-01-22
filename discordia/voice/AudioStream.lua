local Stopwatch = require('../utils/Stopwatch')
local constants = require('./constants')
local timer = require('timer')

local max = math.max
local sleep = timer.sleep
local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

local SILENCE = constants.SILENCE
local PCM_LEN = constants.PCM_LEN
local PCM_SIZE = constants.PCM_SIZE
local FRAME_SIZE = constants.FRAME_SIZE
local MAX_DURATION = constants.MAX_DURATION
local FRAME_DURATION = constants.FRAME_DURATION

local AudioStream = class('AudioStream')

function AudioStream:__init(source, connection)
	self._source = source
	self._connection = connection
end

function AudioStream:play(duration)

	local connection = self._connection
	local client = connection._client

	if connection._closed then
		return client:warning('Attempted to stream audio on a closed connection.')
	end

	duration = duration or MAX_DURATION

	self._stopped = false
	connection._stream = self
	connection._socket:setSpeaking(true)

	local elapsed = 0
	local clock = Stopwatch()
	local encoder = connection._encoder
	local source = self._source

	self._elapsed = elapsed
	self._clock = clock

	while elapsed < duration do
		local pcm = source()
		if not pcm or self._stopped then break end
		local data, len = encoder:encode(pcm, PCM_LEN, FRAME_SIZE, PCM_SIZE)
		if not connection:_send(data, len) then break end
		local delay = FRAME_DURATION + (elapsed - clock.milliseconds)
		elapsed = elapsed + FRAME_DURATION
		self._elapsed = elapsed
		sleep(max(0, delay))
		while self._paused do
			self._paused = running()
			connection:_send(SILENCE, 3)
			clock:pause()
			yield()
			clock:resume()
		end
	end
	connection:_send(SILENCE, 3)

	self._stopped = true
	connection._stream = nil

end

function AudioStream:pause()
	self._paused = true
end

function AudioStream:resume()
	local paused = self._paused
	self._paused = false
	if type(paused) == 'thread' then
		resume(paused)
	end
end

function AudioStream:stop()
	self._stopped = true
	self:resume()
end

return AudioStream
