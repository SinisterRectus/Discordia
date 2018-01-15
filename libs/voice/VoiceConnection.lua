local uv = require('uv')
local ffi = require('ffi')
local constants = require('constants')

local CHANNELS = 2
local SAMPLE_RATE = 48000
local MIN_BITRATE = 8000
local MAX_BITRATE = 128000

local MAX_SEQUENCE = 0xFFFF
local MAX_TIMESTAMP = 0xFFFFFFFF
local FRAME_DURATION = 20 -- ms
local FRAME_SIZE = SAMPLE_RATE * FRAME_DURATION / 1000
local PCM_LEN = FRAME_SIZE * CHANNELS
local PCM_SIZE = PCM_LEN * 2
local HEADER = '>BBI2I4I4'
local PADDING = string.rep('\0', 12)

local MS_PER_NS = 1 / (constants.NS_PER_US * constants.US_PER_MS)

local min, max = math.min, math.max
local band = bit.band
local hrtime = uv.hrtime
local ffi_string = ffi.string
local pack = string.pack -- luacheck: ignore

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

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection, get = require('class')('VoiceConnection')

function VoiceConnection:__init(key, socket)

	self._key = key_t(key)

	self._socket = socket
	self._ip = socket._ip
	self._port = socket._port
	self._udp = socket._udp
	self._state = socket._state
	self._manager = socket._manager
	self._client = socket._client

	self._seq = 0
	self._timestamp = 0

	self._encoder = self._manager._opus.Encoder(SAMPLE_RATE, CHANNELS)
	self:setBitrate(self._client._options.bitrate)

end

function VoiceConnection:getBitrate()
	return self._encoder:get(self._manager._opus.GET_BITRATE_REQUEST)
end

function VoiceConnection:setBitrate(bitrate)
	bitrate = min(max(bitrate, MIN_BITRATE), MAX_BITRATE)
	return self._encoder:set(self._manager._opus.SET_BITRATE_REQUEST, bitrate)
end

function VoiceConnection:_play(source, duration)

	if self._closed then return end

	self._socket:setSpeaking(true)

	local elapsed = 0
	local udp, ip, port = self._udp, self._ip, self._port
	local ssrc, key = self._state.ssrc, self._key
	local encoder = self._encoder
	local encrypt = self._manager._sodium.encrypt

	local t = hrtime()

	while elapsed < (duration or math.huge) do

		local pcm = source(PCM_LEN)
		if not pcm then break end

		local data, len = encoder:encode(pcm, PCM_LEN, FRAME_SIZE, PCM_SIZE)
		if not data then break end

		local seq = self._seq
		local timestamp = self._timestamp

		local header = pack(HEADER, 0x80, 0x78, seq, timestamp, ssrc)

		self._seq = band(seq + 1, MAX_SEQUENCE)
		self._timestamp = band(timestamp + FRAME_SIZE, MAX_TIMESTAMP)

		local encrypted, encrypted_len = encrypt(data, len, header .. PADDING, key)
		if not encrypted then break end

		udp:send(header .. ffi_string(encrypted, encrypted_len), ip, port)

		elapsed = elapsed + FRAME_DURATION
		sleep(max(elapsed - (hrtime() - t) * MS_PER_NS, 0))

	end

	self._socket:setSpeaking(false)

end

function VoiceConnection:close()
	local guild = self.guild
	return guild and self._client._shards[guild.shardId]:updateVoice(guild._id)
end

function get.channel(self)
	local guild = self.guild
	return guild and guild._voice_channels:get(self._state.channel_id)
end

function get.guild(self)
	return self._client._guilds:get(self._state.guild_id)
end

return VoiceConnection
