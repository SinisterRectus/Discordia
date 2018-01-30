local PCMString = require('voice/streams/PCMString')
local PCMGenerator = require('voice/streams/PCMGenerator')
local FFmpegProcess = require('voice/streams/FFmpegProcess')
local Emitter = require('utils/Emitter')

local uv = require('uv')
local ffi = require('ffi')
local constants = require('constants')

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

-- timer.sleep is redefined here to avoid a memory leak in the luvit module
local function sleep(delay)
	local thread = coroutine.running()
	local t = uv.new_timer()
	t:start(delay, 0, function()
		t:stop()
		t:close()
		return assert(coroutine.resume(thread))
	end)
	return coroutine.yield()
end

local function check(n, mn, mx)
	if not tonumber(n) or n < mn or n > mx then
		return error(format('Value must be a number between %s and %s', mn, mx), 2)
	end
	return n
end

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection, get = require('class')('VoiceConnection', Emitter)

function VoiceConnection:__init(channel)
	Emitter.__init(self)
	self._channel = channel
end

function VoiceConnection:_prepare(key, socket)

	self._key = key_t(key)
	self._socket = socket
	self._ip = socket._ip
	self._port = socket._port
	self._udp = socket._udp
	self._ssrc = socket._ssrc
	self._manager = socket._manager
	self._client = socket._client

	self._s = 0
	self._t = 0

	self._encoder = self._manager._opus.Encoder(SAMPLE_RATE, CHANNELS)

	self:setBitrate(self._client._options.bitrate)
	self:setComplexity(COMPLEXITY)

	self._ready = true
	self._pending = nil
	self:emit('ready')

end

function VoiceConnection:_cleanup()
	self._ready = nil
	self._pending = nil
	self._channel._parent._connection = nil
	self._channel._connection = nil
	self:emit('disconnect')
end

function VoiceConnection:getBitrate()
	return self._encoder:get(self._manager._opus.GET_BITRATE_REQUEST)
end

function VoiceConnection:setBitrate(bitrate)
	bitrate = check(bitrate, MIN_BITRATE, MAX_BITRATE)
	self._encoder:set(self._manager._opus.SET_BITRATE_REQUEST, bitrate)
end

function VoiceConnection:getComplexity()
	return self._encoder:get(self._manager._opus.GET_COMPLEXITY_REQUEST)
end

function VoiceConnection:setComplexity(complexity)
	complexity = check(complexity, MIN_COMPLEXITY, MAX_COMPLEXITY)
	self._encoder:set(self._manager._opus.SET_COMPLEXITY_REQUEST, complexity)
end

---- debugging
local skip = 10
local t0, m0
local t_sum, m_sum, count = 0, 0, 0
local function open() -- luacheck: ignore
	-- collectgarbage()
	m0 = collectgarbage('count')
	t0 = hrtime()
end
local function close() -- luacheck: ignore
	local dt = ((hrtime() - t0) * MS_PER_NS)
	local dm = (collectgarbage('count') - m0)
	count = count + 1
	if count > skip then
		t_sum = t_sum + dt
		m_sum = m_sum + dm
		print(dt, dm, t_sum / (count - skip), m_sum / (count - skip))
	end
end
---- debugging

function VoiceConnection:_play(stream, duration)

	self._socket:setSpeaking(true)

	duration = tonumber(duration) or math.huge

	local elapsed = 0
	local udp, ip, port = self._udp, self._ip, self._port
	local ssrc, key = self._ssrc, self._key
	local encoder = self._encoder
	local encrypt = self._manager._sodium.encrypt

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

		local encrypted, encrypted_len = encrypt(data, len, header .. PADDING, key)
		if not encrypted then break end

		udp:send(header .. ffi_string(encrypted, encrypted_len), ip, port)

		elapsed = elapsed + FRAME_DURATION
		sleep(max(elapsed - (hrtime() - start) * MS_PER_NS, 0))

	end

	self._socket:setSpeaking(false)

end

function VoiceConnection:playPCM(source, duration)

	if not self._ready then
		return nil, 'Connection is not ready'
	end

	local stream
	if type(source) == 'string' then
		stream = PCMString(source)
	elseif type(source) == 'function' then
		stream = PCMGenerator(source)
	end

	return self:_play(stream, duration)

end

function VoiceConnection:playFFmpeg(path, duration)

	if not self._ready then
		return nil, 'Connection is not ready'
	end

	local stream = FFmpegProcess(path, SAMPLE_RATE, CHANNELS)
	self:_play(stream, duration)
	return stream:close()

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
