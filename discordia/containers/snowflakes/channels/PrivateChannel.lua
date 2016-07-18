local Channel = require('../Channel')

local PrivateChannel = class('PrivateChannel', Channel)

function PrivateChannel:__init(data, parent)
	Channel.__init(self, data, parent)
end

return PrivateChannel
