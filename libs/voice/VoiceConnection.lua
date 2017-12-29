local ffi = require('ffi')

local key_t = ffi.typeof('const unsigned char[32]')

local VoiceConnection = require('class')('VoiceConnection')

function VoiceConnection:__init(key)
	self._key = key_t(key)
end

return VoiceConnection
