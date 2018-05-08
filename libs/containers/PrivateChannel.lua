--[=[@c PrivateChannel x TextChannel desc]=]

local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function PrivateChannel:close()
	return self:_delete()
end

--[=[@p name type desc]=]
function get.name(self)
	return self._recipient._username
end

--[=[@p recipient type desc]=]
function get.recipient(self)
	return self._recipient
end

return PrivateChannel
