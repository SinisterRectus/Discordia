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

--[[
@method setName
@param name: string
@ret boolean
]]
function GroupChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setIcon
@param icon: Base64 Resolveable
@ret boolean
]]
function GroupChannel:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[[
@method addRecipient
@param id: User ID Resolveable
@ret boolean
]]
function GroupChannel:addRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMAddRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method removeRecipient
@param id: User ID Resolveable
@ret boolean
]]
function GroupChannel:removeRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMRemoveRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method leave
@ret boolean
]]
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
