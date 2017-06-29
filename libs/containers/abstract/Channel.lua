local Snowflake = require('containers/abstract/Snowflake')

local format = string.format

local Channel = require('class')('Channel', Snowflake)
local get = Channel.__getters

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function get.type(self)
	return self._type
end

function get.mentionString(self)
	return format('<#%s>', self._id)
end

return Channel
