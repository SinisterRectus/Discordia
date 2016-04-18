local ServerChannel = require('./serverchannel')

class('ServerVoiceChannel', ServerChannel)

function ServerVoiceChannel:__init(data, server)
    ServerChannel.__init(self, data, server)
    self.bitrate = data.bitrate
end

function ServerVoiceChannel:update(data)
    ServerChannel.update(self, data)
    self.bitrate = data.bitrate
end

return ServerVoiceChannel
