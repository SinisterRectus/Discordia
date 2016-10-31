local User = require('../User')
local TextChannel = require('./TextChannel')

local PrivateChannel, accessors = class('PrivateChannel', TextChannel)

accessors.name = function(self) return self.recipient.username end

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self.recipient = self.client.users:get(data.recipient.id) or self.client.users:new(data.recipient)
	PrivateChannel._update(self, data)
end

function PrivateChannel:_update(data)
	TextChannel._update(self, data)
end

return PrivateChannel
