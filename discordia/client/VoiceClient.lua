local opus = require('../opus')
local sodium = require('../sodium')

local Buffer = require('../utils/Buffer')
local Emitter = require('../utils/Emitter')
local VoiceSocket = require('./VoiceSocket')

local time = os.time
local encrypt = sodium.encrypt

local VoiceClient = class('VoiceClient', Emitter)

function VoiceClient:__init()
	Emitter.__init(self)
	self._encoder = opus.Encoder(48000, 2)
	self._voice_socket = VoiceSocket(self)
	self._seq = 0
	local buffer = Buffer(24)
	buffer[0] = 0x80
	buffer[1] = 0x78
	self._buffer = buffer
end

function VoiceClient:joinChannel(channel, selfMute, selfDeaf)
	local client = channel.client
	client._voice_client = self
	return client._socket:joinVoiceChannel(channel._parent._id, channel._id, selfMute, selfDeaf)
end

function VoiceClient:send(data)

	local buffer = self._buffer
	buffer:writeUInt16BE(2, self._seq)
	buffer:writeUInt32BE(4, time())
	buffer:writeUInt16BE(8, self._ssrc)
	self._seq = self._seq < 65535 and self._seq + 1 or 0

	-- need to opus encode data here
	local encrypted = encrypt(data, buffer._cdata, self._key)
	assert(data == sodium.decrypt(encrypted, buffer._cdata, self._key)) -- debug

	self._udp:send(encrypted, self._ip, self._port)

end

return VoiceClient
