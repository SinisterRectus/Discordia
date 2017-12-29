local GuildChannel = require('containers/abstract/GuildChannel')
local FilteredIterable = require('iterables/FilteredIterable')

local GuildCategoryChannel, get = require('class')('GuildCategoryChannel', GuildChannel)

function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

function GuildCategoryChannel:__serializeJSON(null)
	return {
		type = 'GuildCategoryChannel',

		channel_type = self._type,
		id = self._id,

		permission_overwrites = self._permission_overwrites,
		name = self._name,
		position = self._position,
		parent_id = self._parent_id or null,

		text_channels = (self._text_channels or FilteredIterable(self._parent._text_channels, function(c)
			return c._parent_id == id
		end)):__serializeJSON(null),
		voice_channels = (self._voice_channels or FilteredIterable(self._parent._voice_channels, function(c)
			return c._parent_id == id
		end)):__serializeJSON(null)
	}
end

function get.textChannels(self)
	if not self._text_channels then
		local id = self._id
		self._text_channels = FilteredIterable(self._parent._text_channels, function(c)
			return c._parent_id == id
		end)
	end
	return self._text_channels
end

function get.voiceChannels(self)
	if not self._voice_channels then
		local id = self._id
		self._voice_channels = FilteredIterable(self._parent._voice_channels, function(c)
			return c._parent_id == id
		end)
	end
	return self._voice_channels
end

return GuildCategoryChannel
