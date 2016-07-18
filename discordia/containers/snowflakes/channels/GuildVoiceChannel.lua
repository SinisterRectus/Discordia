local GuildChannel = require('./GuildChannel')
local VoiceChannel = require('./VoiceChannel')

local GuildVoiceChannel = class('GuildVoiceChannel', GuildChannel, VoiceChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	VoiceChannel.__init(self, data, parent)
	GuildVoiceChannel.update(self, data)
end

function GuildVoiceChannel:update(data)
	GuildChannel.update(self, data)
	VoiceChannel.update(self, data)
end

return GuildVoiceChannel
