local Buffer = require('../utils/Buffer')
local ClientBase = require('./ClientBase')
local Stopwatch = require('../utils/Stopwatch')
local VoiceSocket = require('./VoiceSocket')
local timer = require('timer')

local sleep = timer.sleep
local max, clamp = math.max, math.clamp
local unpack, rep, format = string.unpack, string.rep, string.format

local CHANNELS = 2
local SAMPLE_RATE = 48000
local FRAME_DURATION = 20 -- ms
local FRAME_SIZE = SAMPLE_RATE * FRAME_DURATION / 1000
local PCM_SIZE = FRAME_SIZE * CHANNELS * 2
local SILENCE = '\xF8\xFF\xFE'

local defaultOptions = {
	dateTime = '%c',
}

local VoiceClient = class('VoiceClient', ClientBase)

local opus = require('../opus')
function VoiceClient._loadOpus(filename)
	opus = opus(filename)
end

local sodium = require('../sodium')
function VoiceClient._loadSodium(filename)
	sodium = sodium(filename)
end

local ffmpeg
function VoiceClient._loadFFmpeg(filename)
	ffmpeg = filename
end

function VoiceClient:__init(customOptions)
	ClientBase.__init(self, customOptions, defaultOptions)
	if type(opus) == 'function' or type(sodium) == 'function' then
		return self:error('Cannot initialize a VoiceClient before loading voice libraries.')
	end
	self._encoder = opus.Encoder(SAMPLE_RATE, CHANNELS)
	self._encoder:set_bitrate(64000)
	self._voice_socket = VoiceSocket(self)
	self._seq = 0
	self._timestamp = 0
	local header = Buffer(12)
	local nonce = Buffer(24)
	header[0] = 0x80
	header[1] = 0x78
	self._header = header
	self._nonce = nonce
end

function VoiceClient:_prepare(udp, ip, port, ssrc)
	self._udp, self._ip, self._port, self._ssrc = udp, ip, port, ssrc
end

function VoiceClient:joinChannel(channel, selfMute, selfDeaf)
	self._channel = channel
	local client = channel.client
	client._voice_client = self
	return client._socket:joinVoiceChannel(channel._parent._id, channel._id, selfMute, selfDeaf)
end

function VoiceClient:disconnect()
	local channel = self._channel
	if not channel then return end
	local client = channel.client
	client._socket:joinVoiceChannel(channel._parent._id)
	self._voice_socket:disconnect()
end

function VoiceClient:getBitrate()
	return self._encoder:get_bitrate()
end

function VoiceClient:setBitrate(bitrate)
	return self._encoder:set_bitrate(clamp(bitrate, 8000, 128000))
end

local function send(self, data)

	local header = self._header
	local nonce = self._nonce

	header:writeUInt16BE(2, self._seq)
	header:writeUInt32BE(4, self._timestamp)
	header:writeUInt32BE(8, self._ssrc)

	header:copy(nonce)

	self._seq = self._seq < 0xFFFF and self._seq + 1 or 0
	self._timestamp = self._timestamp < 0xFFFFFFFF and self._timestamp + FRAME_SIZE or 0

	local encrypted = sodium.encrypt(data, tostring(nonce), self._key)

	local len = #encrypted
	local packet = Buffer(12 + len)
	header:copy(packet)
	packet:writeString(12, encrypted, len)

	self._udp:send(tostring(packet), self._ip, self._port)

end

local function shorts(str)
    local len = #str / 2
    return {unpack(rep('<H', len), str)}
end

function VoiceClient:play(filename)

	if not ffmpeg then
		return self:warning('FFmpeg not loaded. Cannot play audio files.')
	end

	local socket = self._voice_socket

	if not socket._connected then
		return self:warning(format('Cannot play %q. No voice connection found.', filename))
	end

	self:stop()

	local pipe = io.popen(format('%s -y -i %s -ar 48000 -ac 2 -f s16le pipe:1 -loglevel fatal', ffmpeg, filename))
	self._pipe = pipe

	socket:setSpeaking(true)

	local elapsed = 0
	local clock = Stopwatch()
	local encoder = self._encoder

	while true do
		local success, pcm = pcall(pipe.read, pipe, PCM_SIZE)
		if not success or not pcm then break end
		local data = encoder:encode(shorts(pcm), FRAME_SIZE, PCM_SIZE)
		send(self, data)
		local delay = FRAME_DURATION + (elapsed - clock.milliseconds)
		elapsed = elapsed + FRAME_DURATION
		sleep(max(0, delay))
	end
	send(self, SILENCE)

	pcall(pipe.close, pipe)
	socket:setSpeaking(false)

end

function VoiceClient:stop()
	local pipe = self._pipe
	if not pipe then return end
	pcall(pipe.close, pipe)
end

return VoiceClient
