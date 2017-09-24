local json = require('json')

local TextChannel = require('containers/abstract/TextChannel')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local GroupChannel, get = require('class')('GroupChannel', TextChannel)

function GroupChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipients = SecondaryCache(data.recipients, self.client._users)
end

function GroupChannel:setName(name)
	return self:_modify({name = name or json.null})
end

function GroupChannel:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

function GroupChannel:addRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMAddRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

function GroupChannel:removeRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMRemoveRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

function GroupChannel:leave()
	return self:_delete()
end

function get.recipients(self)
	return self._recipients
end

function get.name(self)
	return self._name
end

function get.ownerId(self)
	return self._owner_id
end

function get.owner(self)
	return self._recipients:get(self._owner_id)
end

function get.icon(self)
	return self._icon
end

function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon)
end

return GroupChannel
