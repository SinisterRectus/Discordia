local Snowflake = require('containers/abstract/Snowflake')

local PermissionOverwrite = require('class')('PermissionOverwrite', Snowflake)

function PermissionOverwrite:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

return PermissionOverwrite
