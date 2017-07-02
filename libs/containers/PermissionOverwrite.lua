local Snowflake = require('containers/abstract/Snowflake')
local Permissions = require('utils/Permissions')

local PermissionOverwrite = require('class')('PermissionOverwrite', Snowflake)
local get = PermissionOverwrite.__getters

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function PermissionOverwrite:delete()
	local data, err = self.client.api:deleteChannelPermission(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
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
