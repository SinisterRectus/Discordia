local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel = require('class')('PrivateChannel', TextChannel)
local get = PrivateChannel.__getters

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

function get.name(self)
	return self._recipient._username
end

function get.recipient(self)
	return self._recipient
end

return PrivateChannel
