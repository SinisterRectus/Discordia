--[=[@c GroupChannel x TextChannel ...]=]

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
@p name string
@r boolean
@d ...
]=]
function GroupChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setIcon
@p icon Base64-Resolvable
@r boolean
@d ...
]=]
function GroupChannel:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[=[
@m addRecipient
@p id User-ID-Resolvable
@r boolean
@d ...
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
@p id User-ID-Resolvable
@r boolean
@d ...
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
@r boolean
@d ...
]=]
function GroupChannel:leave()
	return self:_delete()
end

--[=[@p recipients SecondaryCache ...]=]
function get.recipients(self)
	return self._recipients
end

--[=[@p name string ...]=]
function get.name(self)
	return self._name
end

--[=[@p ownerId string ...]=]
function get.ownerId(self)
	return self._owner_id
end

--[=[@p owner User|nil ...]=]
function get.owner(self)
	return self._recipients:get(self._owner_id)
end

--[=[@p icon string|nil ...]=]
function get.icon(self)
	return self._icon
end

--[=[@p iconURL string|nil ...]=]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/channel-icons/%s/%s.png', self._id, icon)
end

return GroupChannel
