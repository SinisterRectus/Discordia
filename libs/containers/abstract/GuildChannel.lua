local json = require('json')

local Channel = require('containers/abstract/Channel')
local PermissionOverwrite = require('containers/PermissionOverwrite')
local Invite = require('containers/Invite')
local Cache = require('iterables/Cache')

local GuildChannel = require('class')('GuildChannel', Channel)
local get = GuildChannel.__getters

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

function GuildChannel:setName(name)
	return self:_modify({name = name or json.null})
end

function GuildChannel:createInvite(max_age, max_uses, temporary, unique) -- all are optional
	local data, err = self.client._api:createChannelInvite(self._id, {
		max_age = max_age, -- number, default = 86400 (24 hours)
		max_uses = max_uses, -- number, default = 0 (unlimited)
		temporary = temporary, -- boolean, default = false
		unique = unique, -- boolean, default = false
	})
	if data then
		return Invite(data, self.client)
	else
		return nil, err
	end
end

function GuildChannel:getInvites()
	local data, err = self.client._api:getChannelInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

-- TODO: position setting

function get.permissionOverwrites(self)
	return self._permission_overwrites
end

function get.name(self)
	return self._name
end

function get.position(self)
	return self._position
end

function get.guild(self)
	return self._parent
end

return GuildChannel
