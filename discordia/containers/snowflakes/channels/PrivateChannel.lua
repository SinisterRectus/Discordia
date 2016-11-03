local User = require('../User')
local TextChannel = require('./TextChannel')

local format = string.format

local PrivateChannel, property = class('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	local users = self._parent._users
	self._recipient = users:get(data.recipient.id) or users:new(data.recipient)
	PrivateChannel._update(self, data)
end

property('recipient', '_recipient', nil, 'User', "The recipient of the private channel (the other half of your conversation)")

property('name', function(self)
	return self._recipient._username
end, nil, 'string', "The username of the channel recipient")

function PrivateChannel:__tostring()
	return format('%s: %s', self.__name, self._recipient._username)
end

function PrivateChannel:_update(data)
	TextChannel._update(self, data)
end

return PrivateChannel
