local GuildChannel = require('containers/abstract/GuildChannel')
local FilteredIterable = require('iterables/FilteredIterable')
local enums = require('enums')

local channelType = enums.channelType

local GuildCategoryChannel, get = require('class')('GuildCategoryChannel', GuildChannel)

function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

function GuildCategoryChannel:createTextChannel(name)
	local guild = self._parent
	local data, err = guild.client._api:createGuildChannel(guild._id, {
		name = name,
		type = channelType.text,
		parent_id = self._id
	})
	if data then
		return guild._text_channels:_insert(data)
	else
		return nil, err
	end
end

function GuildCategoryChannel:createVoiceChannel(name)
	local guild = self._parent
	local data, err = guild.client._api:createGuildChannel(guild._id, {
		name = name,
		type = channelType.voice,
		parent_id = self._id
	})
	if data then
		return guild._voice_channels:_insert(data)
	else
		return nil, err
	end
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
