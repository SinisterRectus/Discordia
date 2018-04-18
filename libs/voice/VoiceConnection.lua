local PCMString = require('voice/streams/PCMString')
local PCMStream = require('voice/streams/PCMStream')
local PCMGenerator = require('voice/streams/PCMGenerator')

local uv = require('uv')
local ffi = require('ffi')
local constants = require('constants')
local opus = require('voice/opus')
local sodium = require('voice/sodium')

local CHANNELS = 2
local SAMPLE_RATE = 48000 -- Hz
local FRAME_DURATION = 20 -- ms
local COMPLEXITY = 5

local MIN_BITRATE = 8000 -- bps
local MAX_BITRATE = 128000 -- bps
local MIN_COMPLEXITY = 0
local MAX_COMPLEXITY = 10

local MAX_SEQUENCE = 0xFFFF
local MAX_TIMESTAMP = 0xFFFFFFFF

local HEADER_FMT = '>BBI2I4I4'
local PADDING = string.rep('\0', 12)

local MS_PER_NS = 1 / (constants.NS_PER_US * constants.US_PER_MS)
local MS_PER_S = constants.MS_PER_S

local max = math.max
local hrtime = uv.hrtime
local ffi_string = ffi.string
local pack = string.pack -- luacheck: ignore
local format = string.format
local insert = table.insert
local running, resume, yield = coroutine.running, coroutine.resume, coroutine.yield

-- timer.sleep is redefined here to avoid a memory leak in the luvit module
local function sleep(delay)
	local thread = running()
	local t = uv.new_timer()
	t:start(delay, 0, function()
		t:stop()
		t:close()
		return assert(resume(thread))
	end)
	return yield()
end

local function asyncResume(thread)
	local t = uv.new_timer()
	t:start(0, 0, function()
		t:stop()
		t:close()
		return assert(resume(thread))
	end)
end

local function check(n, mn, mx)
	if not tonumber(n) or n < mn or n > mx then
		return error(format('Value must be a number between %s and %s', mn, mx), 2)
	end
	return n
end

local VoiceConnection, get = require('class')('VoiceConnection')

function VoiceConnection:__init(channel)
	self._channel = channel
	self._pending = {}
end

function VoiceConnection:_prepare(key, socket)

	self._key = sodium.key(key)
	self._socket = socket
	self._ip = socket._ip
	self._port = socket._port
	self._udp = socket._udp
	self._ssrc = socket._ssrc
	self._mode = socket._mode
	self._manager = socket._manager
	self._client = socket._client

	self._s = 0
	self._t = 0

	self._encoder = opus.Encoder(SAMPLE_RATE, CHANNELS)

	self:setBitrate(self._client._options.bitrate)
	self:setComplexity(COMPLEXITY)

	self._ready = true
	self:_continue(true)

end

function VoiceConnection:_await()
	local thread = running()
	insert(self._pending, thread)
	if not self._timeout then
		local t = uv.new_timer()
		t:start(10000, 0, function()
			t:stop()
			t:close()
			self._timeout = nil
			if not self._ready then
				local id = self._channel and self._channel._id
				return self:_cleanup(format('voice connection for channel %s failed to initialize', id))
			end
		end)
		self._timeout = t
	end
	return yield()
end

function VoiceConnection:_continue(success, err)
	local t = self._timeout
	if t then
		t:stop()
		t:close()
		self._timeout = nil
	end
	for i, thread in ipairs(self._pending) do
		self._pending[i] = nil
		assert(resume(thread, success, err))
	end
end

function VoiceConnection:_cleanup(err)
	self:stopStream()
	self._ready = nil
	self._channel._parent._connection = nil
	self._channel._connection = nil
	self:_continue(nil, err or 'connection closed')
end

function VoiceConnection:getBitrate()
	return self._encoder:get(opus.GET_BITRATE_REQUEST)
end

function VoiceConnection:setBitrate(bitrate)
	bitrate = check(bitrate, MIN_BITRATE, MAX_BITRATE)
	self._encoder:set(opus.SET_BITRATE_REQUEST, bitrate)
end

function VoiceConnection:getComplexity()
	return self._encoder:get(opus.GET_COMPLEXITY_REQUEST)
end

function VoiceConnection:setComplexity(complexity)
	complexity = check(complexity, MIN_COMPLEXITY, MAX_COMPLEXITY)
	self._encoder:set(opus.SET_COMPLEXITY_REQUEST, complexity)
end

---- debugging
local t0, m0
local t_sum, m_sum, n = 0, 0, 0
local function open() -- luacheck: ignore
	-- collectgarbage()
	m0 = collectgarbage('count')
	t0 = hrtime()
end
local function close() -- luacheck: ignore
	local dt = (hrtime() - t0) * MS_PER_NS
	local dm = collectgarbage('count') - m0
	n = n + 1
	t_sum = t_sum + dt
	m_sum = m_sum + dm
	print(format('dt: %g | dm: %g | avg dt: %g | avg dm: %g', dt, dm, t_sum / n, m_sum / n))
end
---- debugging

function VoiceConnection:_play(stream, duration)

	self:stopStream()
	self:_setSpeaking(true)

	duration = tonumber(duration) or math.huge

	local elapsed = 0
	local udp, ip, port = self._udp, self._ip, self._port
	local ssrc, key = self._ssrc, self._key
	local encoder = self._encoder

	local frame_size = SAMPLE_RATE * FRAME_DURATION / MS_PER_S
	local pcm_len = frame_size * CHANNELS

	local start = hrtime()

	while elapsed < duration do

		local pcm = stream:read(pcm_len)
		if not pcm then break end

		local data, len = encoder:encode(pcm, pcm_len, frame_size, pcm_len * 2)
		if not data then break end

		local s, t = self._s, self._t
		local header = pack(HEADER_FMT, 0x80, 0x78, s, t, ssrc)

		s = s + 1
		t = t + frame_size

		self._s = s > MAX_SEQUENCE and 0 or s
		self._t = t > MAX_TIMESTAMP and 0 or t

		local encrypted, encrypted_len = sodium.encrypt(data, len, header .. PADDING, key)
		if not encrypted then break end

		local packet = header .. ffi_string(encrypted, encrypted_len)
		udp:send(packet, ip, port)

		elapsed = elapsed + FRAME_DURATION
		local delay = elapsed - (hrtime() - start) * MS_PER_NS
		sleep(max(delay, 0))

		if self._paused then
			asyncResume(self._paused)
			self._paused = running()
			local pause = hrtime()
			yield()
			start = start + hrtime() - pause
			asyncResume(self._resumed)
			self._resumed = nil
		end

		if self._stopped then break	end

	end

	self:_setSpeaking(false)

	if self._stopped then
		asyncResume(self._stopped)
		self._stopped = nil
	end

end

function VoiceConnection:_setSpeaking(speaking)
	self._speaking = speaking
	return self._socket:setSpeaking(speaking)
end

function VoiceConnection:playPCM(source, duration)

	if not self._ready then
		return nil, 'Connection is not ready'
	end

	local t = type(source)

	local stream
	if t == 'string' then
		stream = PCMString(source)
	elseif t == 'function' then
		stream = PCMGenerator(source)
	elseif (t == 'table' or t == 'userdata') and type(source.read) == 'function' then
		stream = PCMStream(source)
	else
		return error('Invalid audio source: ' .. tostring(source))
	end

	return self:_play(stream, duration)

end

function VoiceConnection:playFFmpeg(path, duration)

	if not self._ready then
		return nil, 'Connection is not ready'
	end

	local cmd = format('ffmpeg -i %q -ar %i -ac %i -f s16le pipe:1 -loglevel warning', path, SAMPLE_RATE, CHANNELS)
	local source = assert(io.popen(cmd))
	local stream = PCMStream(source)

	self:_play(stream, duration)
	source:close()

end

function VoiceConnection:pauseStream()
	if not self._speaking then return end
	if self._paused then return end
	self._paused = running()
	return yield()
end

function VoiceConnection:resumeStream()
	if not self._speaking then return end
	if not self._paused then return end
	asyncResume(self._paused)
	self._paused = nil
	self._resumed = running()
	return yield()
end

function VoiceConnection:stopStream()
	if not self._speaking then return end
	if self._stopped then return end
	self._stopped = running()
	self:resumeStream()
	return yield()
end

function VoiceConnection:close()
	if self._socket then
		self._socket:disconnect()
	end
	local guild = self._channel._parent
	return self._client._shards[guild.shardId]:updateVoice(guild._id)
end

function get.channel(self)
	return self._channel
end

return VoiceConnection
