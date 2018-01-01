local ffi = require('ffi')
local constants = require('constants')

local CHANNELS = constants.CHANNELS
local SAMPLE_RATE = constants.SAMPLE_RATE
local MIN_BITRATE = constants.MIN_BITRATE
local MAX_BITRATE = constants.MAX_BITRATE

local min, max = math.min, math.max

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection, get = require('class')('VoiceConnection')

function VoiceConnection:__init(key, channel, manager)
	self._key = key_t(key)
	self._channel = channel
	self._manager = manager
	self._encoder = self._manager._opus.Encoder(SAMPLE_RATE, CHANNELS)
	self:setBitrate(manager._client._options.bitrate)
end

function VoiceConnection:getBitrate()
	return self._encoder:get(self._manager._opus.GET_BITRATE_REQUEST)
end

function VoiceConnection:setBitrate(bitrate)
	bitrate = min(max(bitrate, MIN_BITRATE), MAX_BITRATE)
	return self._encoder:set(self._manager._opus.SET_BITRATE_REQUEST, bitrate)
end

function VoiceConnection:close()
	local guild = self._channel._parent
	local client = self._manager._client
	return client._shards[guild.shardId]:updateVoice(guild._id)
end

function get.channel(self)
	return self._channel
end

function get.guild(self)
	return self._channel._parent
end

return VoiceConnection
