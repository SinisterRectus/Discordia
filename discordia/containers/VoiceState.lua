local Container = require('../utils/Container')

local format = string.format

local VoiceState, get = class('VoiceState', Container)

function VoiceState:__init(data, parent)
	Container.__init(self, data, parent)
	self:_update(data)
end

get('guild', '_parent')
get('userId', '_user_id')
get('sessionId', '_session_id')
get('channelId', '_channel_id')
get('mute', '_mute')
get('deaf', '_deaf')
get('selfMute', '_self_mute')
get('selfDeaf', '_self_deaf')
get('suppress', '_suppress')

function VoiceState:__tostring()
	return format('%s: %s', self.__name, self._session_id)
end

function VoiceState:__eq(other)
	return self.__class == other.__class and self._session_id == other._session_id
end

return VoiceState
