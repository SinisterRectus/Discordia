local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

--[[
@method close
@ret boolean
]]
function PrivateChannel:close()
	return self:_delete()
end

--[[
@property name: string
]]
function get.name(self)
	return self._recipient._username
end

--[[
@property recipient: User
]]
function get.recipient(self)
	return self._recipient
end

return PrivateChannel
