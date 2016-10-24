local GuildChannel = require('./GuildChannel')
local TextChannel = require('./TextChannel')

local GuildTextChannel = class('GuildTextChannel', GuildChannel, TextChannel)

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
	GuildTextChannel.update(self, data)
end

function GuildTextChannel:update(data)
	GuildChannel.update(self, data)
	TextChannel.update(self, data)
	self.topic = data.topic
end

function GuildTextChannel:setTopic(topic)
	local success, data = self.client.api:modifyChannel(self.id, {topic = topic})
	if success then self.topic = data.topic end
	return success
end

function GuildTextChannel:getMentionString()
	return string.format('<#%s>', self.id)
end

return GuildTextChannel
