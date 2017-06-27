local Channel = require('containers/abstract/Channel')
local Message = require('containers/Message')
local WeakCache = require('iterables/WeakCache')

local TextChannel = require('class')('TextChannel', Channel)
local get = TextChannel.__getters

function TextChannel:__init(data, parent)
	Channel.__init(self, data, parent)
    self._messages = WeakCache(Message, self)
end

function get.messages(self)
	return self._messages
end

return TextChannel
