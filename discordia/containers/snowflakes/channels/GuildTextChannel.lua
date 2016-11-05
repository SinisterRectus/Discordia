local GuildChannel = require('./GuildChannel')
local TextChannel = require('./TextChannel')

local format = string.format

local GuildTextChannel, property = class('GuildTextChannel', TextChannel, GuildChannel)
GuildTextChannel.__description = "Represents a Discord guild text channel."

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
	GuildTextChannel._update(self, data)
end

function GuildTextChannel:_update(data)
	GuildChannel._update(self, data)
	TextChannel._update(self, data)
end

local function getMentionString(self)
	return format('<#%s>', self._id)
end

local function setTopic(self, topic)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {topic = topic})
	if success then self._topic = data.topic end
	return success
end

property('mentionString', getMentionString, nil, 'string', "Raw string that is parsed by Discord into a user mention")
property('topic', '_topic', setTopic, 'string', "The channel topic (at the top of the channel in the Discord client)")

return GuildTextChannel
