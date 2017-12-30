local ffi = require('ffi')

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection, get = require('class')('VoiceConnection')

function VoiceConnection:__init(key, channel, manager)
	self._key = key_t(key)
	self._channel = channel -- TODO: maybe switch to updating state for propogating updates
	self._manager = manager
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
