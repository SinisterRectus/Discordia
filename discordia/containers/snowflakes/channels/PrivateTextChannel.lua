local User = require('../User')
local PrivateChannel = require('./PrivateChannel')
local TextChannel = require('./TextChannel')

local PrivateTextChannel, accessors = class('PrivateTextChannel', PrivateChannel, TextChannel)

accessors.name = function(self) return self.recipient.username end

function PrivateTextChannel:__init(data, parent)
	PrivateChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
	self.recipient = self.client:getUserById(data.recipient.id) or self.client.users:new(data.recipient)
end

return PrivateTextChannel
