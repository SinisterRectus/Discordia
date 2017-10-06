local GuildChannel = require('containers/abstract/GuildChannel')
local FilteredIterable = require('iterables/FilteredIterable')

local GuildCategoryChannel, get = require('class')('GuildCategoryChannel', GuildChannel)

function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
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
