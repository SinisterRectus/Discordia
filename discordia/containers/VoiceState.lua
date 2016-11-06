local Container = require('../utils/Container')

local format = string.format

local VoiceState, property = class('VoiceState', Container)
VoiceState.__description = "Represents a guild member's connection to a voice channel"

function VoiceState:__init(data, parent)
	Container.__init(self, data, parent)
	self:_update(data)
end

function VoiceState:__tostring()
	return format('%s: %s', self.__name, self._session_id)
end

function VoiceState:__eq(other)
	return self.__name == other.__name and self._session_id == other._session_id
end

local function getUser(self)
	return self._parent._parent:queryUser(self._user_id)
end

local function getChannel(self)
	return self._parent._voice_channels:get(self._channel_id)
end

property('sessionId', '_session_id', nil, 'string', "The session ID for the voice state")
property('guild', '_parent', nil, 'Guild', "The guild in which the voice state exists")
property('mute', '_mute', nil, 'boolean', "Whether the user is muted by the guild")
property('deaf', '_deaf', nil, 'boolean', "Whether the user is deafened by the guild")
property('selfMute', '_self_mute', nil, 'boolean', "Whether the user is locally muted")
property('selfDeaf', '_self_deaf', nil, 'boolean', "Whether the user is locally deafened")
property('suppress', '_suppress', nil, 'boolean', "Whether the user is muted by the client")
property('user', getUser, nil, 'string', "The user for which the voice state exists")
property('channel', getChannel, nil, 'string', "The channel in which the voice state exists")

return VoiceState
