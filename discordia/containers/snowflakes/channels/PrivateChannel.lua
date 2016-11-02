local User = require('../User')
local TextChannel = require('./TextChannel')

local PrivateChannel, get = class('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	local users = self._parent._users
	self._recipient = users:get(data.recipient.id) or users:new(data.recipient)
	PrivateChannel._update(self, data)
end

function PrivateChannel:_update(data)
	TextChannel._update(self, data)
end

get('recipient', '_recipient')

get('name', function(self)
	return self._recipient._username
end)

return PrivateChannel
