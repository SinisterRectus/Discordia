--[=[
@c VoiceConnection
@d Represents a connection to a Discord voice server.
]=]

local PCMString = require('voice/streams/PCMString')
local PCMStream = require('voice/streams/PCMStream')
local PCMGenerator = require('voice/streams/PCMGenerator')
local FFmpegProcess = require('voice/streams/FFmpegProcess')

local uv = require('uv')
local ffi = require('ffi')
local bit = require('bit')
local constants = require('constants')
local opus = require('voice/opus') or {}
local sodium = require('voice/sodium') or {}

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
local MAX_NONCE = 0xFFFFFFFF

local HEADER_FMT = '>BBI2I4I4'

local MS_PER_NS = 1 / (constants.NS_PER_US * constants.US_PER_MS)
local MS_PER_S = constants.MS_PER_S

local FRAME_SIZE = SAMPLE_RATE * FRAME_DURATION / MS_PER_S

local max = math.max
local hrtime = uv.hrtime
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

	self._socket = socket
	self._ip = socket._ip
	self._port = socket._port
	self._udp = socket._udp
	self._ssrc = socket._ssrc
	self._mode = socket._mode
	self._manager = socket._manager
	self._client = socket._client

	if self._mode == 'aead_xchacha20_poly1305_rtpsize' then
		self._crypto = sodium.aead_xchacha20_poly1305
	elseif self._mode == 'aead_aes256_gcm_rtpsize' then
		self._crypto = sodium.aead_aes256_gcm
	else
		return error('unsupported encryption mode: ' .. self._mode)
	end

	self._key = self._crypto.key(key)
	self._s = sodium.random() % (MAX_SEQUENCE + 1)
	self._t = sodium.random() % (MAX_TIMESTAMP + 1)
	self._n = 0

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

--[=[
@m getBitrate
@t mem
@r nil
@d Returns the bitrate of the interal Opus encoder in bits per second (bps).
]=]
function VoiceConnection:getBitrate()
	return self._encoder:get(opus.GET_BITRATE_REQUEST)
end

--[=[
@m setBitrate
@t mem
@p bitrate number
@r nil
@d Sets the bitrate of the interal Opus encoder in bits per second (bps).
This should be between 8000 and 128000, inclusive.
]=]
function VoiceConnection:setBitrate(bitrate)
	bitrate = check(bitrate, MIN_BITRATE, MAX_BITRATE)
	self._encoder:set(opus.SET_BITRATE_REQUEST, bitrate)
end

--[=[
@m getComplexity
@t mem
@r number
@d Returns the complexity of the interal Opus encoder.
]=]
function VoiceConnection:getComplexity()
	return self._encoder:get(opus.GET_COMPLEXITY_REQUEST)
end

--[=[
@m setComplexity
@t mem
@p complexity number
@r nil
@d Sets the complexity of the interal Opus encoder.
This should be between 0 and 10, inclusive.
]=]
function VoiceConnection:setComplexity(complexity)
	complexity = check(complexity, MIN_COMPLEXITY, MAX_COMPLEXITY)
	self._encoder:set(opus.SET_COMPLEXITY_REQUEST, complexity)
end

function VoiceConnection:_createAudioPacket(opus_data, opus_len, ssrc, key)
	local s, t, n = self._s, self._t, self._n

	s = s + 1
	t = t + FRAME_SIZE
	n = n + 1

	self._s = s >= MAX_SEQUENCE and 0 or s
	self._t = t >= MAX_TIMESTAMP and 0 or t
	self._n = n >= MAX_NONCE and 0 or n

	local header = pack(HEADER_FMT, 0x80, 0x78, s, t, ssrc)

	local nonce = self._crypto.nonce(n)
	local nonce_padding = ffi.string(nonce, 4)

	local ciphertext, ciphertext_len = self._crypto.encrypt(opus_data, opus_len, header, #header, nonce, key)
	if not ciphertext then
		return nil, ciphertext_len -- report error
	end

	return header .. ffi.string(ciphertext, ciphertext_len) .. nonce_padding

end

function VoiceConnection:_parseAudioPacket(packet, key)

	if #packet < 12 then
		return nil, 'packet too short'
	end

	local first_byte, payload_type, sequence, timestamp, ssrc = string.unpack(HEADER_FMT, packet)

	local rtp_version = bit.rshift(first_byte, 6)
	local has_padding = bit.band(first_byte, 0x20) == 0x20
	local has_extension = bit.band(first_byte, 0x10) == 0x10
	local num_csrc = bit.band(first_byte, 0x0F)
	if rtp_version ~= 2 then
		return nil, 'invalid RTP version'
	elseif payload_type ~= 0x78 then
		return nil, 'invalid payload type'
	end

	local header_len = 12 + num_csrc * 4
	local extension_len = 0

	if has_extension then
		extension_len = string.unpack('>I2', packet, header_len + 3) * 4
		header_len = header_len + 4
	end

	local payload = ffi.cast('const char *', packet) + header_len
	local payload_len = #packet - header_len - 4

	if payload_len < 0 then
		return nil, 'invalid payload length'
	end

	local nonce_bytes = packet:sub(-4)
	local nonce = self._crypto.nonce(nonce_bytes)

	local message, message_len = self._crypto.decrypt(payload, payload_len, packet, header_len, nonce, key)
	if not message then
		return nil, message_len -- report error
	end

	if has_padding then
		local padding_len = message[message_len - 1]
		if padding_len > message_len then
			return nil, 'invalid padding length'
		end
		message_len = message_len - padding_len
	end

	return ffi.string(message + extension_len, message_len - extension_len), sequence, timestamp, ssrc

end

function VoiceConnection:_play(stream, duration)

	self:stopStream()
	self:_setSpeaking(true)

	duration = tonumber(duration) or math.huge

	local elapsed = 0
	local udp, ip, port = self._udp, self._ip, self._port
	local ssrc, key = self._ssrc, self._key
	local encoder = self._encoder

	local pcm_len = FRAME_SIZE * CHANNELS

	local start = hrtime()
	local reason

	while elapsed < duration do

		local pcm = stream:read(pcm_len)
		if not pcm then
			reason = 'stream exhausted or errored'
			break
		end

		local data, data_len = encoder:encode(pcm, pcm_len, FRAME_SIZE, pcm_len * 2)
		if not data then
			reason = 'could not encode audio data'
			break
		end

		local packet, err = self:_createAudioPacket(data, data_len, ssrc, key)
		if not packet then
			reason = err
			break
		end

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

		if self._stopped then
			reason = 'stream stopped'
			break
		end

	end

	self:_setSpeaking(false)

	if self._stopped then
		asyncResume(self._stopped)
		self._stopped = nil
	end

	return elapsed, reason

end

function VoiceConnection:_setSpeaking(speaking)
	self._speaking = speaking
	return self._socket:setSpeaking(speaking)
end

--[=[
@m playPCM
@t mem
@p source string/function/table/userdata
@op duration number
@r number
@r string
@d Plays PCM data over the established connection. If a duration (in milliseconds)
is provided, the audio stream will automatically stop after that time has elapsed;
otherwise, it will play until the source is exhausted. The returned number is the
time elapsed while streaming and the returned string is a message detailing the
reason why the stream stopped. For more information about acceptable sources,
see the [[voice]] page.
]=]
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

--[=[
@m playFFmpeg
@t mem
@p path string
@op duration number
@r number
@r string
@d Plays audio over the established connection using an FFmpeg process, assuming
FFmpeg is properly configured. If a duration (in milliseconds)
is provided, the audio stream will automatically stop after that time has elapsed;
otherwise, it will play until the source is exhausted. The returned number is the
time elapsed while streaming and the returned string is a message detailing the
reason why the stream stopped. For more information about using FFmpeg,
see the [[voice]] page.
]=]
function VoiceConnection:playFFmpeg(path, duration)

	if not self._ready then
		return nil, 'Connection is not ready'
	end

	local stream = FFmpegProcess(path, SAMPLE_RATE, CHANNELS)

	local elapsed, reason = self:_play(stream, duration)
	stream:close()
	return elapsed, reason

end

--[=[
@m pauseStream
@t mem
@r nil
@d Temporarily pauses the audio stream for this connection, if one is active.
Like most Discordia methods, this must be called inside of a coroutine, as it
will yield until the stream is actually paused, usually on the next tick.
]=]
function VoiceConnection:pauseStream()
	if not self._speaking then return end
	if self._paused then return end
	self._paused = running()
	return yield()
end

--[=[
@m resumeStream
@t mem
@r nil
@d Resumes the audio stream for this connection, if one is active and paused.
Like most Discordia methods, this must be called inside of a coroutine, as it
will yield until the stream is actually resumed, usually on the next tick.
]=]
function VoiceConnection:resumeStream()
	if not self._speaking then return end
	if not self._paused then return end
	asyncResume(self._paused)
	self._paused = nil
	self._resumed = running()
	return yield()
end

--[=[
@m stopStream
@t mem
@r nil
@d Irreversibly stops the audio stream for this connection, if one is active.
Like most Discordia methods, this must be called inside of a coroutine, as it
will yield until the stream is actually stopped, usually on the next tick.
]=]
function VoiceConnection:stopStream()
	if not self._speaking then return end
	if self._stopped then return end
	self._stopped = running()
	self:resumeStream()
	return yield()
end

--[=[
@m close
@t ws
@r boolean
@d Stops the audio stream for this connection, if one is active, disconnects from
the voice server, and leaves the corresponding voice channel. Like most Discordia
methods, this must be called inside of a coroutine.
]=]
function VoiceConnection:close()
	self:stopStream()
	if self._socket then
		self._socket:disconnect()
	end
	local guild = self._channel._parent
	return self._client._shards[guild.shardId]:updateVoice(guild._id)
end

--[=[@p channel GuildVoiceChannel/nil The corresponding GuildVoiceChannel for
this connection, if one exists.]=]
function get.channel(self)
	return self._channel
end

return VoiceConnection
