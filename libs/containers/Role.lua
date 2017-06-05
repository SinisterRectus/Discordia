local Snowflake = require('containers/abstract/Snowflake')

local Role = require('class')('Role', Snowflake)

function Role:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

return Role
