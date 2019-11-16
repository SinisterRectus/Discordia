--[=[
@c PrivateChannel x TextChannel
@d Represents a private Discord text channel used to track correspondences between
the current user and one other recipient.
]=]

local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

--[=[
@m close
@t http
@r boolean
@d Closes the channel. This does not delete the channel. To re-open the channel,
use `User:getPrivateChannel`.
]=]
function PrivateChannel:close()
	return self:_delete()
end

--[=[@p name string Equivalent to `PrivateChannel.recipient.username`.]=]
function get.name(self)
	return self._recipient._username
end

--[=[@p recipient User The recipient of this channel's messages, other than the current user.]=]
function get.recipient(self)
	return self._recipient
end

return PrivateChannel
