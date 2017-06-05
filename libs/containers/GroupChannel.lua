local TextChannel = require('containers/abstract/TextChannel')

local GroupChannel = require('class')('GroupChannel', TextChannel)

function GroupChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	local users = self.client._users
	local recipients = data.recipients
	for i, recipient in ipairs(recipients) do
		recipients[recipient.id] = users:insert(recipient)
		recipients[i] = nil
	end
	self._recipients = recipients
end

return GroupChannel
