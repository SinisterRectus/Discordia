local TextChannel = require('./textchannel')
local ServerChannel = require('./serverchannel')

local ServerTextChannel = class('ServerTextChannel', ServerChannel, TextChannel)

function ServerTextChannel:__init(data, server)

	ServerChannel.__init(self, data, server)
	TextChannel.__init(self, data, server.client)

end

function ServerTextChannel:setTopic(topic)
	self:edit(nil, nil, topic, nil)
end

function ServerTextChannel:getMentionString()
	return string.format('<#%s>', self.id)
end

return ServerTextChannel
