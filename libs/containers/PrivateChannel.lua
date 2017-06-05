local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:insert(data.recipients[1])
end

return PrivateChannel
