local json = require('json')
local enums = require('enums')
local class = require('class')
local Channel = require('containers/abstract/Channel')
local PermissionOverwrite = require('containers/PermissionOverwrite')
local Invite = require('containers/Invite')
local Cache = require('iterables/Cache')

local isInstance = class.isInstance
local classes = class.classes
local channelType = enums.channelType

local insert, sort = table.insert, table.sort
local min, max, floor = math.min, math.max, math.floor
local huge = math.huge

local GuildChannel, get = class('GuildChannel', Channel)

--[[
@abc GuildChannel x Channel

Abstract base class that defines the base methods and/or properties for all
Discord guild channels.
]]
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

--[[
@method setName
@tags http
@param name: string
@ret boolean

Sets the channel's name. This must be between 2 and 100 characters in length.
]]
function GuildChannel:setName(name)
	return self:_modify({name = name or json.null})
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
	if self._type == channelType.text then
		channels = self._parent._text_channels
	else
		channels = self._parent._voice_channels
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

--[[
@method moveUp
@tags http
@param [n]: number
@ret boolean

Moves a channel up its list. The parameter `n` indicates how many spaces the
channel should be moved, clamped to the highest position, with a default of 1 if
it is omitted. This will also normalize the positions of all channels.
]]
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

--[[
@method moveDown
@tags http
@param [n]: number
@ret boolean

Moves a channel down its list. The parameter `n` indicates how many spaces the
channel should be moved, clamped to the lowest position, with a default of 1 if
it is omitted. This will also normalize the positions of all channels.
]]
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

--[[
@method createInvite
@tags http
@param [payload]: table
@ret Invite

Creates an invite to the channel. Optional payload fields are:
- max_age:number time in seconds until expiration, default = 86400 (24 hours)
- max_uses:number total number of uses allowed, default = 0 (unlimited)
- temporary:boolean whether the invite grants temporary membership, default = false
- unique:boolean whether a unique code should be guaranteed, default = false
]]
function GuildChannel:createInvite(payload)
	local data, err = self.client._api:createChannelInvite(self._id, payload)
	if data then
		return Invite(data, self.client)
	else
		return nil, err
	end
end

--[[
@method getInvites
@tags http
@ret Cache

Returns a newly constructed cache of all invite objects for the channel. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]]
function GuildChannel:getInvites()
	local data, err = self.client._api:getChannelInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

--[[
@method getPermissionOverwriteFor
@param object: Role|Member
@ret PermissionOverwrite

Returns a permission overwrite object corresponding to the provided member or
role object. If a cached overwrite is not found, an empty overwrite with
zero-permissions is returned instead. Therefore, this can be used to create a
new overwrite when one does not exist. Note that the member or role must exist
in the same guild as the channel does.
]]
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

--[[
@method delete
@tags http
@ret boolean

Permanently deletes the channel. This cannot be undone!
]]
function GuildChannel:delete()
	return self:_delete()
end

--[[
@property permissionOverwrites: Cache

An iterable cache of all overwrites that exist in this channel. To access an
overwrite that may exist, but is not cached, use `$:getPermissionOverwriteFor`.
]]
function get.permissionOverwrites(self)
	return self._permission_overwrites
end

--[[
@property name: string

The name of the channel. This should be between 2 and 100 characters in length.
]]
function get.name(self)
	return self._name
end

--[[
@property position: number

The position of the channel, where 0 is the highest.
]]
function get.position(self)
	return self._position
end

--[[
@property guild: Guild

The guild in which this channel exists. Equivalent to `$.parent`.
]]
function get.guild(self)
	return self._parent
end

return GuildChannel
