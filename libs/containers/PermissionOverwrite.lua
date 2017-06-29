local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')

local PermissionOverwrite = require('class')('PermissionOverwrite', Snowflake)
local get = PermissionOverwrite.__getters

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function get.type(self)
	return self._type
end

function get.channel(self)
	return self._channel
end

function get.allowedPermissions(self)
	return Permissions(self._allow)
end

function get.deniedPermissions(self)
	return Permissions(self._deny)
end

return PermissionOverwrite
