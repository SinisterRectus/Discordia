local Cache = require('../../../utils/Cache')
local Invite = require('../../Invite')
local Channel = require('../Channel')
local PermissionOverwrite = require('../PermissionOverwrite')

local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local GuildChannel, property, method = class('GuildChannel', Channel)
GuildChannel.__description = "Abstract base class for guild text and voice channels."

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self._permission_overwrites = Cache({}, PermissionOverwrite, '_id', self)
	-- abstract class, don't call update
end

function GuildChannel:__tostring()
	return format('%s: %s', self.__name, self._name)
end

function GuildChannel:_update(data)
	Channel._update(self, data)
	local overwrites = self._permission_overwrites
	if #data.permission_overwrites > 0 then
		local updated = {}
		for _, data in ipairs(data.permission_overwrites) do
			updated[data.id] = true
			local overwrite = overwrites:get(data.id)
			if overwrite then
				overwrite:_update(data)
			else
				overwrite = overwrites:new(data)
			end
		end
		for overwrite in overwrites:iter() do
			if not updated[overwrite._id] then
				overwrites:remove(overwrite)
			end
		end
	end
end

local function setName(self, name)
	local success, data = self._parent._parent._api:modifyChannel(self._id, {name = name})
	if success then self._name = data.name end
	return success
end

local function setPosition(self, position) -- will probably need more abstraction
	local success, data = self._parent._parent._api:modifyChannel(self._id, {position = position})
	if success then self._position = data.position end
	return success
end

local function getPermissionOverwriteFor(self, object)
	local type = type(object) == 'table' and object.__name:lower() or nil
	if type ~= 'role' and type ~= 'member' then return end
	local id = object._id
	return self._permission_overwrites:get(id) or self._permission_overwrites:new({
		id = id, allow = 0, deny = 0, type = type
	})
end

local function getInvites(self)
	local client = self._parent._parent
	local success, data = client._api:getChannelInvites(self._id)
	if not success then return function() end end
	return wrap(function()
		for _, inviteData in ipairs(data) do
			yield(Invite(inviteData, client))
		end
	end)
end

local function createInvite(self, maxAge, maxUses, temporary, unique)
	local client = self._parent._parent
	local success, data = client._api:createChannelInvite(self._id, {
		max_age = maxAge,
		max_uses = maxUses,
		temporary = temporary,
		unique = unique
	})
	if success then return Invite(data, client) end
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
property('permissionOverwriteCount', getPermissionOverwriteCount, nil, 'number', "How many permission overwrites are cached for this channel")
property('permissionOverwrites', getPermissionOverwrites, nil, 'function', "Iterator for cached permission overwrites")

method('createInvite', createInvite, 'maxAge, maxUses, temporary, unique', "Creates and returns an invite to the channel for users to join.")
method('getPermissionOverwriteFor', getPermissionOverwriteFor, 'object', 'Returns a PermissionOverwrite for the provided Role or Member object.')
method('getPermissionOverwrite', getPermissionOverwrite, '[key,] value', 'Returns the first cached PermissionOverwrite that matches the (key, value) pair.')
method('getPermissionOverwrites', getPermissionOverwrites, 'key, value', 'Returns all cached PermissionOverwrite that match the (key, value) pair.')
method('findPermissionOverwrite', findPermissionOverwrite, 'predicate', 'Returns the first cached PermissionOverwrite that satisfies a predicate.')
method('findPermissionOverwrites', findPermissionOverwrites, 'predicate', 'Returns an iterator for all cached PermissionOverwrites that satisfy a predicate.')

return GuildChannel
