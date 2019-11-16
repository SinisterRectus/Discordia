--[=[
@c GuildCategoryChannel x GuildChannel
@d Represents a channel category in a Discord guild, used to organize individual
text or voice channels in that guild.
]=]

local GuildChannel = require('containers/abstract/GuildChannel')
local FilteredIterable = require('iterables/FilteredIterable')
local enums = require('enums')

local channelType = enums.channelType

local GuildCategoryChannel, get = require('class')('GuildCategoryChannel', GuildChannel)

function GuildCategoryChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

--[=[
@m createTextChannel
@t http
@p name string
@r GuildTextChannel
@d Creates a new GuildTextChannel with this category as it's parent. Similar to `Guild:createTextChannel(name)`
]=]
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

--[=[
@m createVoiceChannel
@t http
@p name string
@r GuildVoiceChannel
@d Creates a new GuildVoiceChannel with this category as it's parent. Similar to `Guild:createVoiceChannel(name)`
]=]
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

--[=[@p textChannels FilteredIterable Iterable of all textChannels in the Category.]=]
function get.textChannels(self)
	if not self._text_channels then
		local id = self._id
		self._text_channels = FilteredIterable(self._parent._text_channels, function(c)
			return c._parent_id == id
		end)
	end
	return self._text_channels
end

--[=[@p voiceChannels FilteredIterable Iterable of all voiceChannels in the Category.]=]
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
