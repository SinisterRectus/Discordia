local Cache = require('../../../utils/Cache')
local Invite = require('../../Invite')
local Channel = require('../Channel')
local PermissionOverwrite = require('../PermissionOverwrite')

local GuildChannel, accessors = class('GuildChannel', Channel)

accessors.guild = function(self) return self.parent end

function GuildChannel:__init(data, parent)
	Channel.__init(self, data, parent)
	self.permissionOverwrites = Cache({}, PermissionOverwrite, 'id', self)
	GuildChannel.update(self, data)
end

function GuildChannel:update(data)
	self.name = data.name
	self.position = data.position
	local updated = {}
	for _, data in ipairs(data.permission_overwrites) do
		updated[data.id] = true
		local overwrite = self.permissionOverwrites:get(data.id)
		if overwrite then
			overwrite:update(data)
		else
			overwrite = self.permissionOverwrites:new(data)
		end
	end
	for overwrite in self.permissionOverwrites:iter() do
		if not updated[overwrite.id] then
			self.permissionOverwrites:remove(overwrite)
		end
	end
end

function GuildChannel:setName(name)
	local success, data = self.client.api:modifyChannel(self.id, {name = name})
	if success then self.name = data.name end
	return success
end

function GuildChannel:setPosition(position) -- will probably need more abstraction
	local success, data = self.client.api:modifyChannel(self.id, {position = position})
	if success then self.position = data.position end
	return success
end

function GuildChannel:getInvites()
	local success, data = self.client.api:getChannelInvites(self.id)
	if success then return Cache(data, Invite, 'code', self.client) end
end

function GuildChannel:createInvite(maxAge, maxUses, temporary, unique)
	local success, data = self.client.api:createChannelInvite(self.id, {
		max_age = maxAge,
		max_uses = maxUses,
		temporary = temporary,
		unique = unique
	})
	if success then return Invite(data, self.client) end
end

return GuildChannel
