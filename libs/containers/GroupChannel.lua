local TextChannel = require('containers/abstract/TextChannel')
local SecondaryCache = require('iterables/SecondaryCache')

local GroupChannel = require('class')('GroupChannel', TextChannel)
local get = GroupChannel.__getters

function GroupChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipients = SecondaryCache(data.recipients, self.client._users)
end

function get.recipients(self)
	return self._recipients
end

return GroupChannel
