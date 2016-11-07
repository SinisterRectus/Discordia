local Container = require('../utils/Container')

local format = string.format

local VoiceState = class('VoiceState', Container)

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

return VoiceState
