--[=[
@c GuildVoiceChannel x GuildChannel
@d Represents a voice channel in a Discord guild, where guild members can connect
and communicate via voice chat.
]=]

local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')
local VoiceConnection = require('voice/VoiceConnection')
local TableIterable = require('iterables/TableIterable')

local GuildVoiceChannel, get = require('class')('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

--[=[
@m setBitrate
@p bitrate number
@r boolean
@d Sets the channel's audio bitrate in bits per second (bps). This must be between
8000 and 96000 (or 128000 for partnered servers). If `nil` is passed, the
default is set, which is 64000.
]=]
function GuildVoiceChannel:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate or json.null})
end

--[=[
@m setUserLimit
@p user_limit number
@r boolean
@d Sets the channel's user limit. This must be between 0 and 99 (where 0 is
unlimited). If `nil` is passed, the default is set, which is 0.
]=]
function GuildVoiceChannel:setUserLimit(user_limit)
	return self:_modify({user_limit = user_limit or json.null})
end

--[=[
@m join
@r VoiceConnection
@d description
]=]
function GuildVoiceChannel:join()

	local success, err

	local connection = self._connection

	if connection then

		if connection._ready then
			return connection
		end

	else

		local guild = self._parent
		local client = guild._parent

		success, err = client._shards[guild.shardId]:updateVoice(guild._id, self._id)

		if not success then
			return nil, err
		end

		connection = guild._connection

		if not connection then
			connection = VoiceConnection(self)
			guild._connection = connection
		end

		self._connection = connection

	end

	success, err = connection:_await()

	if success then
		return connection
	else
		return nil, err
	end

end

--[=[@p bitrate number The channel's bitrate in bits per second (bps). This should be between 8000 and
96000 (or 128000 for partnered servers).]=]
function get.bitrate(self)
	return self._bitrate
end

--[=[@p userLimit number ...]=]
function get.userLimit(self)
	return self._user_limit
end

--[=[@p connectedMembers TableIterable The channel's user limit. This should between 0 and 99 (where 0 is unlimited).]=]
function get.connectedMembers(self)
	if not self._members then
		local id = self._id
		local members = self._parent._members
		self._members = TableIterable(self._parent._voice_states, function(state)
			return state.channel_id == id and members:get(state.user_id)
		end)
	end
	return self._members
end

--[=[@p connection type description]=]
function get.connection(self)
	return self._connection
end

return GuildVoiceChannel
