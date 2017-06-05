local Snowflake = require('containers/abstract/Snowflake')

local User = require('class')('User', Snowflake)

function User:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

return User
