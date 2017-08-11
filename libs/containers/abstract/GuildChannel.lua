local json = require('json')
local class = require('class')
local Channel = require('containers/abstract/Channel')
local PermissionOverwrite = require('containers/PermissionOverwrite')
local Invite = require('containers/Invite')
local Cache = require('iterables/Cache')

local isInstance = class.isInstance
local classes = class.classes

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

--[[
@method setName
@param name: string
@ret boolean
]]
function GuildChannel:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setPosition
@param position: number
@ret boolean
]]
function GuildChannel:setPosition(position)
	return self:_modify({position = position or json.null})
end

--[[
@method createInvite
@param payload: table
@ret Invite
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
@ret Cache
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
@ret boolean
]]
function GuildChannel:delete()
	return self:_delete()
end

--[[
@property permissionOverwrites: Cache
]]
function get.permissionOverwrites(self)
	return self._permission_overwrites
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property position: number
]]
function get.position(self)
	return self._position
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent
end

return GuildChannel
