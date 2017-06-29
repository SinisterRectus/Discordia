local TextChannel = require('containers/abstract/TextChannel')
local SecondaryCache = require('iterables/SecondaryCache')

local format = string.format

local GroupChannel = require('class')('GroupChannel', TextChannel)
local get = GroupChannel.__getters

function GroupChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipients = SecondaryCache(data.recipients, self.client._users)
end

function get.recipients(self)
	return self._recipients
end

function get.name(self)
	return self._name -- or 'Unnamed'?
end

function get.owner(self) -- TODO: probably need to parse relationships for this
	return self.client._users:get(self._owner_id)
end

function get.icon(self)
	return self._icon
end

function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon) or nil
end

return GroupChannel
