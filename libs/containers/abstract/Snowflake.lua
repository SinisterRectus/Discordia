local Container = require('utils/Container')

local Snowflake = require('class')('Snowflake', Container)

function Snowflake:__init(data, parent)
	Container.__init(self, data, parent)
end

function Snowflake:__hash()
	return self._id
end

return Snowflake
