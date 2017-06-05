local Snowflake = require('containers/abstract/Snowflake')

local Channel = require('class')('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

return Channel
