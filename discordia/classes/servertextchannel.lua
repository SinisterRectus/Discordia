local TextChannel = require('./textchannel')
local ServerChannel = require('./serverchannel')

class('ServerTextChannel', ServerChannel, TextChannel)

function ServerTextChannel:__init(data, server)

    ServerChannel.__init(self, data, server)
    TextChannel.__init(self, data, server.client)

end

return ServerTextChannel
