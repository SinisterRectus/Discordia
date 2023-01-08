--[=[
@c Channel x Snowflake
@t abc
@d Defines the base methods and properties for all Discord channel types.
]=]

local Snowflake = require('containers/abstract/Snowflake')
local enums = require('enums')

local format = string.format
local channelType = assert(enums.channelType)

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
		local cache
		local t = self._type
		if t == channelType.text or t == channelType.news then
			cache = self._parent._text_channels
		elseif t == channelType.private then
			cache = self._parent._private_channels
		elseif t == channelType.group then
			cache = self._parent._group_channels
		elseif t == channelType.voice then
			cache = self._parent._voice_channels
		elseif t == channelType.category then
			cache = self._parent._categories
		end
		if cache then
			cache:_delete(self._id)
		end
		return true
	else
		return false, err
	end
end

--[=[@p type number The channel type. See the `channelType` enumeration for a
human-readable representation.]=]
function get.type(self)
	return self._type
end

--[=[@p mentionString string A string that, when included in a message content,
may resolve as a link to a channel in the official Discord client.]=]
function get.mentionString(self)
	return format('<#%s>', self._id)
end

return Channel
