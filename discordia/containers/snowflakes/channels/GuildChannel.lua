local Cache = require('../../../utils/Cache')
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

return GuildChannel
