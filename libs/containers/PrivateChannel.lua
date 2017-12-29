local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

function PrivateChannel:close()
	return self:_delete()
end

function PrivateChannel:__json(null)
	return {
		type = 'PrivateChannel',

		channel_type = self._type,
		id = self._id,

		messages = self._messages:__json(null),

		name = self._recipient._username,
		recipient = self._recipient:__json(null)
	}
end

function get.name(self)
	return self._recipient._username
end

function get.recipient(self)
	return self._recipient
end

return PrivateChannel
