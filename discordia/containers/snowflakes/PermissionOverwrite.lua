local Snowflake = require('../Snowflake')
local Permissions = require('../../utils/Permissions')

local PermissionOverwrite, accessors = class('PermissionOverwrite', Snowflake)

accessors.channel = function(self) return self.parent end

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
	Permissions.__init(self, data.allow, data.deny)
	self.type = data.type
end

function PermissionOverwrite:update(data)
	self.allow = Permissions(data.allow)
	self.deny = Permissions(data.deny)
end

return PermissionOverwrite
