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
@p name string
@r GuildTextChannel
@d Creates a new GuildTextChannel with this category as it's parent. `Guild:createTextChannel(name)`
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

--[=[@p textChannels FilteredIterable Returns all textChannels in the Category]=]
local _text_channels = setmetatable({}, {__mode = 'v'})
function get.textChannels(self)
	if not _text_channels[self] then
		local id = self._id
		_text_channels[self] = FilteredIterable(self._parent._text_channels, function(c)
			return c._parent_id == id
		end)
	end
	return _text_channels[self]
end

--[=[@p voiceChannels FilteredIterable Returns all voiceChannels in the Category]=]
local _voice_channels = setmetatable({}, {__mode = 'v'})
function get.voiceChannels(self)
	if not _voice_channels[self] then
		local id = self._id
		_voice_channels[self] = FilteredIterable(self._parent._voice_channels, function(c)
			return c._parent_id == id
		end)
	end
	return _voice_channels[self]
end

return GuildCategoryChannel
