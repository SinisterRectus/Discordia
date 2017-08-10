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

function GroupChannel:leave()
	return self:_delete()
end

--[[
@property recipients: SecondaryCache
]]
function get.recipients(self)
	return self._recipients
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property ownerId: string
]]
function get.ownerId(self)
	return self._owner_id
end

--[[
@property owner: User
]]
function get.owner(self)
	return self.client._users:get(self._owner_id)
end

--[[
@property icon: string|nil
]]
function get.icon(self)
	return self._icon
end

--[[
@property iconURL: string|nil
]]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon)
end

return GroupChannel
