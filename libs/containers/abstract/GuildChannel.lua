--[=[@abc GuildChannel x Channel desc]=]

local json = require('json')
local enums = require('enums')
local class = require('class')
local Channel = require('containers/abstract/Channel')
local PermissionOverwrite = require('containers/PermissionOverwrite')
local Invite = require('containers/Invite')
local Cache = require('iterables/Cache')
local Resolver = require('client/Resolver')

local isInstance = class.isInstance
local classes = class.classes
local channelType = enums.channelType

local insert, sort = table.insert, table.sort
local min, max, floor = math.min, math.max, math.floor
local huge = math.huge

local GuildChannel, get = class('GuildChannel', Channel)

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self.client._channel_map[self._id] = parent
	self._permission_overwrites = Cache({}, PermissionOverwrite, self)
	return self:_loadMore(data)
end

function GuildChannel:_load(data)
	Channel._load(self, data)
	return self:_loadMore(data)
end

function GuildChannel:_loadMore(data)
	return self._permission_overwrites:_load(data.permission_overwrites, true)
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:setCategory(id)
	id = Resolver.channelId(id)
	return self:_modify({parent_id = id or json.null})
end

local function sorter(a, b)
	if a.position == b.position then
		return tonumber(a.id) < tonumber(b.id)
	else
		return a.position < b.position
	end
end

local function getSortedChannels(self)

	local channels
	local t = self._type
	if t == channelType.text then
		channels = self._parent._text_channels
	elseif t == channelType.voice then
		channels = self._parent._voice_channels
	elseif t == channelType.category then
		channels = self._parent._categories
	end

	local ret = {}
	for channel in channels:iter() do
		insert(ret, {id = channel._id, position = channel._position})
	end
	sort(ret, sorter)

	return ret

end

local function setSortedChannels(self, channels)
	local data, err = self.client._api:modifyGuildChannelPositions(self._parent._id, channels)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:moveUp(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveDown(-n)
	end

	local channels = getSortedChannels(self)

	local new = huge
	for i = #channels - 1, 0, -1 do
		local v = channels[i + 1]
		if v.id == self._id then
			new = max(0, i - floor(n))
			v.position = new
		elseif i >= new then
			v.position = i + 1
		else
			v.position = i
		end
	end

	return setSortedChannels(self, channels)

end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:moveDown(n)

	n = tonumber(n) or 1
	if n < 0 then
		return self:moveUp(-n)
	end

	local channels = getSortedChannels(self)

	local new = -huge
	for i = 0, #channels - 1 do
		local v = channels[i + 1]
		if v.id == self._id then
			new = min(i + floor(n), #channels - 1)
			v.position = new
		elseif i <= new then
			v.position = i - 1
		else
			v.position = i
		end
	end

	return setSortedChannels(self, channels)

end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:createInvite(payload)
	local data, err = self.client._api:createChannelInvite(self._id, payload)
	if data then
		return Invite(data, self.client)
	else
		return nil, err
	end
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:getInvites()
	local data, err = self.client._api:getChannelInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:getPermissionOverwriteFor(obj)
	local id, type
	if isInstance(obj, classes.Role) and self._parent == obj._parent then
		id, type = obj._id, 'role'
	elseif isInstance(obj, classes.Member) and self._parent == obj._parent then
		id, type = obj._user._id, 'member'
	else
		return nil, 'Invalid Role or Member: ' .. tostring(obj)
	end
	local overwrites = self._permission_overwrites
	return overwrites:get(id) or overwrites:_insert(setmetatable({
		id = id, type = type, allow = 0, deny = 0
	}, {__jsontype = 'object'}))
end

--[=[
@m name
@p name type
@r type
@d desc
]=]
function GuildChannel:delete()
	return self:_delete()
end

--[=[@p permissionOverwrites type desc]=]
function get.permissionOverwrites(self)
	return self._permission_overwrites
end

--[=[@p name type desc]=]
function get.name(self)
	return self._name
end

--[=[@p position type desc]=]
function get.position(self)
	return self._position
end

--[=[@p guild type desc]=]
function get.guild(self)
	return self._parent
end

--[=[@p category type desc]=]
function get.category(self)
	return self._parent._categories:get(self._parent_id)
end

return GuildChannel
