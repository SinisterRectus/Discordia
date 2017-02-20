local Cache = require('../../../utils/Cache')
local Invite = require('../../Invite')
local Channel = require('../Channel')
local PermissionOverwrite = require('../PermissionOverwrite')

local format = string.format

local GuildChannel, property, method, cache = class('GuildChannel', Channel)
GuildChannel.__description = "Abstract base class for guild text and voice channels."

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self._permission_overwrites = Cache({}, PermissionOverwrite, 'id', self)
	-- abstract class, don't call update
end

function GuildChannel:__tostring()
	return format('%s: %s', self.__name, self._name)
end

function GuildChannel:_update(data)
	Channel._update(self, data)
	if #data.permission_overwrites > 0 then
		self._permission_overwrites:_update(data.permission_overwrites)
	end
end

local function setName(self, name)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {name = name})
	if success then self._name = data.name end
	return success
end

local function setPosition(self, position) -- TODO: add position corrections
	local success, data = self._parent._parent._api:modifyChannel(self._id, {position = position})
	if success then self._position = data.position end
	return success
end

local function getPermissionOverwriteFor(self, object)
	local type = type(object) == 'table' and object.__name:lower()
	if type ~= 'role' and type ~= 'member' then return nil end
	local id = object._id
	return self._permission_overwrites:get(id) or self._permission_overwrites:new({
		id = id, allow = 0, deny = 0, type = type
	})
end

local function getInvites(self)
	local client = self._parent._parent
	local success, data = client._api:getChannelInvites(self._id)
	if not success then return function() end end
	local i = 1
	return function()
		local v = data[i]
		if v then
			i = i + 1
			return Invite(v, client)
		end
	end
end

local function createInvite(self, maxAge, maxUses, temporary, unique)
	local client = self._parent._parent
	local success, data = client._api:createChannelInvite(self._id, {
		max_age = maxAge,
		max_uses = maxUses,
		temporary = temporary,
		unique = unique
	})
	return success and Invite(data, client) or nil
end

-- permission overwrite --

local function getPermissionOverwriteCount(self)
	return self._permission_overwrites._count
end

local function getPermissionOverwrites(self, key, value)
	return self._permission_overwrites:getAll(key, value)
end

local function getPermissionOverwrite(self, key, value)
	return self._permission_overwrites:get(key, value)
end

local function findPermissionOverwrite(self, predicate)
	return self._permission_overwrites:find(predicate)
end

local function findPermissionOverwrites(self, predicate)
	return self._permission_overwrites:findAll(predicate)
end

property('guild', '_parent', nil, 'Guild', "The guild in which the channel exists")
property('name', '_name', setName, 'string', "The name of the guild channel")
property('position', '_position', setPosition, 'number', "The position of the channel in the guild's list of channels")
property('invites', getInvites, nil, 'function', "Returns an iterator for the channel's invites (not cached)")

method('createInvite', createInvite, 'maxAge, maxUses, temporary, unique', "Creates and returns an invite to the channel for users to join.")
method('getPermissionOverwriteFor', getPermissionOverwriteFor, 'object', "Returns an overwrite for the provided Role or Member")

cache('PermissionOverwrite', getPermissionOverwriteCount, getPermissionOverwrite, getPermissionOverwrites, findPermissionOverwrite, findPermissionOverwrites)

return GuildChannel
