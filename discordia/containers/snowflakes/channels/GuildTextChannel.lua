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
	return success
end

return GuildTextChannel
