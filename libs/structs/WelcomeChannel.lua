local class = require('../class')
local Struct = require('./Struct')

local WelcomeChannel, get = class('WelcomeChannel', Struct)

function WelcomeChannel:__init(data)
	Struct.__init(self, data)
end

function get:channelId()
	return self._channel_id
end

function get:description()
	return self._description
end

function get:emojiId()
	return self._emoji_id
end

function get:emojiName()
	return self._emoji_name
end

return WelcomeChannel
