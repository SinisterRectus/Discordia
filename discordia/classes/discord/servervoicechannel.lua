local ServerChannel = require('./serverchannel')

local ServerVoiceChannel = class('ServerVoiceChannel', ServerChannel)

function ServerVoiceChannel:__init(data, server)
	ServerChannel.__init(self, data, server)
	self.bitrate = data.bitrate
end

function ServerVoiceChannel:update(data)
	ServerChannel.update(self, data)
	self.bitrate = data.bitrate
end

function ServerVoiceChannel:setBitrate(bitrate)
	self:edit(nil, nil, nil, bitrate)
end

return ServerVoiceChannel
