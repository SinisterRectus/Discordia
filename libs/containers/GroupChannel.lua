local json = require('json')

local TextChannel = require('containers/abstract/TextChannel')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local GroupChannel = require('class')('GroupChannel', TextChannel)
local get = GroupChannel.__getters

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

-- TODO: need to figure out other methods
-- creating (group vs private)
-- deleting (does it delete for everyone or just leave?)
-- start call (is a group channel necessary to start a call?)
-- is owner mutable?

function GroupChannel:addRecipient(user)
	user = Resolver.userId(user)
	local data, err = self.client._api:groupDMAddRecipient(self._id, user)
	if data then
		return true
	else
		return false, err
	end
end

function GroupChannel:removeRecipient(user)
	user = Resolver.userId(user)
	local data, err = self.client._api:groupDMRemoveRecipient(self._id, user)
	if data then
		return true
	else
		return false, err
	end
end

function get.recipients(self)
	return self._recipients
end

function get.name(self)
	return self._name
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
