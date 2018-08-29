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
@d Join this channel and form a connection to the Voice Gateway.
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

--[=[
@m leave
@r boolean
@d Leave this channel if there is an existing voice connection to it.
Equivalent to GuildVoiceChannel.connection:close()
]=]
function GuildVoiceChannel:leave()
	if self._connection then
		return self._connection:close()
	else
		return false, 'No voice connection exists for this channel'
	end
end

--[=[@p bitrate number The channel's bitrate in bits per second (bps). This should be between 8000 and
96000 (or 128000 for partnered servers).]=]
function get.bitrate(self)
	return self._bitrate
end

--[=[@p userLimit number The amount of users allowed to be in this channel.
Users with `moveMembers` permission ignore this limit.]=]
function get.userLimit(self)
	return self._user_limit
end

--[=[@p connectedMembers TableIterable The channel's user limit. This should between 0 and 99 (where 0 is unlimited).]=]
local _connected_members = setmetatable({}, {__mode = 'v'})
function get.connectedMembers(self)
	if not _connected_members[self] then
		local id = self._id
		local members = self._parent._members
		_connected_members[self] = TableIterable(self._parent._voice_states, function(state)
			return state.channel_id == id and members:get(state.user_id)
		end)
	end
	return _connected_members[self]
end

--[=[@p connection VoiceConnection/nil The VoiceConnection for this channel if one exists.]=]
function get.connection(self)
	return self._connection
end

return GuildVoiceChannel
