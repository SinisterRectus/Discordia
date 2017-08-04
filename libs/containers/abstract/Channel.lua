local Snowflake = require('containers/abstract/Snowflake')

local format = string.format

local Channel, get = require('class')('Channel', Snowflake)

function Channel:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Channel:_modify(payload)
	local data, err = self.client._api:modifyChannel(self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Channel:_delete()
	local data, err = self.client._api:deleteChannel(self._id)
	if data then
		return true
	else
		return false, err
	end
end

function get.type(self)
	return self._type
end

function get.mentionString(self)
	return format('<#%s>', self._id)
end

return Channel
