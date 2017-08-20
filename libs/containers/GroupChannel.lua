local json = require('json')

local TextChannel = require('containers/abstract/TextChannel')
local SecondaryCache = require('iterables/SecondaryCache')
local Resolver = require('client/Resolver')

local format = string.format

local GroupChannel, get = require('class')('GroupChannel', TextChannel)

--[[
@class GroupChannel x TextChannel

Represents a Discord group channel. Essentially a private channel that may have
more than one and up to ten recipients. This class should only be relevant to
user-accounts; bots cannot normally join group channels.
]]
function GroupChannel:__init(data, parent)
	TextChannel.__init(self, data, parent)
	self._recipients = SecondaryCache(data.recipients, self.client._users)
end

--[[
@method setName
@tags http
@param name: string
@ret boolean

Sets the channel's name. This must be between 1 and 100 characters in length.
]]
function GroupChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setIcon
@tags http
@param icon: Base64 Resolveable
@ret boolean

Sets the channels's icon. To remove the icon, pass `nil`.
]]
function GroupChannel:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[[
@method addRecipient
@tags http
@param id: User ID Resolveable
@ret boolean

Adds a user to the channel.
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
@tags http
@param id: User ID Resolveable
@ret boolean

Removes a user from the channel.
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
@tags http
@ret boolean

Removes the client's user from the channel. If no users remain, the channel
is destroyed.
]]
function GroupChannel:leave()
	return self:_delete()
end

--[[
@property recipients: SecondaryCache

A secondary cache of users that are present in the channel.
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

The Snowflake ID of the user that owns (created) the channel.
]]
function get.ownerId(self)
	return self._owner_id
end

--[[
@property owner: User

Equivalent to `$.recipients:get($.ownerId)`.
]]
function get.owner(self)
	return self._recipients:get(self._owner_id)
end

--[[
@property icon: string|nil

The hash for the channel's custom icon, if one is set.
]]
function get.icon(self)
	return self._icon
end

--[[
@property iconURL: string|nil

The URL that can be used to view the channels's icon, if one is set.
]]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon)
end

return GroupChannel
