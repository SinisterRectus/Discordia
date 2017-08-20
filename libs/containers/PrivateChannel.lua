local TextChannel = require('containers/abstract/TextChannel')

local PrivateChannel, get = require('class')('PrivateChannel', TextChannel)

--[[
@class PrivateChannel x TextChannel

Represents a private Discord text channel used to track correspondences between
the current user and one other recipient.
]]
function PrivateChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipient = self.client._users:_insert(data.recipients[1])
end

--[[
@method close
@tags http
@ret boolean

Closes the channel. This does not delete the channel. To re-open the channel,
use `User:getPrivateChannel`.
]]
function PrivateChannel:close()
	return self:_delete()
end

--[[
@property name: string

Equivalent to `$.recipient.username`.
]]
function get.name(self)
	return self._recipient._username
end

--[[
@property recipient: User

The recipient of this channel's messages, other than the current user.
]]
function get.recipient(self)
	return self._recipient
end

return PrivateChannel
