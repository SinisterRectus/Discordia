--[=[
@c GroupChannel x TextChannel
@d Represents a Discord group channel. Essentially a private channel that may have
more than one and up to ten recipients. This class should only be relevant to
user-accounts; bots cannot normally join group channels.
]=]

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

--[=[
@m setName
@t http
@p name string
@r boolean
@d Sets the channel's name. This must be between 1 and 100 characters in length.
]=]
function GroupChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setIcon
@t http
@p icon Base64-Resolvable
@r boolean
@d Sets the channel's icon. To remove the icon, pass `nil`.
]=]
function GroupChannel:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[=[
@m addRecipient
@t http
@p id User-ID-Resolvable
@r boolean
@d Adds a user to the channel.
]=]
function GroupChannel:addRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMAddRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m removeRecipient
@t http
@p id User-ID-Resolvable
@r boolean
@d Removes a user from the channel.
]=]
function GroupChannel:removeRecipient(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:groupDMRemoveRecipient(self._id, id)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m leave
@t http
@r boolean
@d Removes the client's user from the channel. If no users remain, the channel
is destroyed.
]=]
function GroupChannel:leave()
	return self:_delete()
end

--[=[@p recipients SecondaryCache A secondary cache of users that are present in the channel.]=]
function get.recipients(self)
	return self._recipients
end

--[=[@p name string The name of the channel.]=]
function get.name(self)
	return self._name
end

--[=[@p ownerId string The Snowflake ID of the user that owns (created) the channel.]=]
function get.ownerId(self)
	return self._owner_id
end

--[=[@p owner User/nil Equivalent to `GroupChannel.recipients:get(GroupChannel.ownerId)`.]=]
function get.owner(self)
	return self._recipients:get(self._owner_id)
end

--[=[@p icon string/nil The hash for the channel's custom icon, if one is set.]=]
function get.icon(self)
	return self._icon
end

--[=[@p iconURL string/nil The URL that can be used to view the channel's icon, if one is set.]=]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon)
end

return GroupChannel
