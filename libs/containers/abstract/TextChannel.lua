local Channel = require('containers/abstract/Channel')
local Message = require('containers/Message')
local OrderedCache = require('utils/OrderedCache')

local TextChannel = require('class')('TextChannel', Channel)

-- TODO: put "uncached" messges into a weak table or weak cache

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
    self._messages = OrderedCache(Message, self)
end

return TextChannel
