local class = require('../class')

local WelcomeChannel, get = class('WelcomeChannel')

function WelcomeChannel:__init(data)
	self._channel_id = data.channel_id
	self._description = data.description
	self._emoji_id = data.emoji_id
	self._emoji_name = data.emoji_name
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
