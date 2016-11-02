local Container = require('../utils/Container')

local format = string.format

local VoiceState, get = class('VoiceState', Container)

function VoiceState:__init(data, parent)
	Container.__init(self, data, parent)
	self:_update(data)
end

get('guild', '_parent', 'Guild')
get('userId', '_user_id', 'string')
get('sessionId', '_session_id', 'string')
get('channelId', '_channel_id', 'string')
get('mute', '_mute', 'boolean')
get('deaf', '_deaf', 'boolean')
get('selfMute', '_self_mute', 'boolean')
get('selfDeaf', '_self_deaf', 'boolean')
get('suppress', '_suppress', 'boolean')

function VoiceState:__tostring()
	return format('%s: %s', self.__name, self._session_id)
end

function VoiceState:__eq(other)
	return self.__class == other.__class and self._session_id == other._session_id
end

return VoiceState
