local Channel = require('containers/abstract/Channel')
local Message = require('containers/Message')
local WeakCache = require('utils/WeakCache')

local TextChannel = require('class')('TextChannel', Channel)

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
    self._messages = WeakCache(Message, self)
end

return TextChannel
