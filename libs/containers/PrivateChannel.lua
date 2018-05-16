--[=[@c PrivateChannel x TextChannel ...]=]

local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

--[=[
@m close
@r boolean
@d ...
]=]
function PrivateChannel:close()
	return self:_delete()
end

--[=[@p name string ...]=]
function get.name(self)
	return self._recipient._username
end

--[=[@p recipient User ...]=]
function get.recipient(self)
	return self._recipient
end

return PrivateChannel
