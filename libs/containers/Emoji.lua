local Snowflake = require('containers/abstract/Snowflake')

local Emoji = require('class')('Emoji', Snowflake)

function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

return Emoji
