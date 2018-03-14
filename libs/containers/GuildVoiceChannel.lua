local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')
local VoiceConnection = require('voice/VoiceConnection')
local TableIterable = require('iterables/TableIterable')

local GuildVoiceChannel, get = require('class')('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
end

function GuildVoiceChannel:setBitrate(bitrate)
	return self:_modify({bitrate = bitrate or json.null})
end

function GuildVoiceChannel:setUserLimit(user_limit)
	return self:_modify({user_limit = user_limit or json.null})
end

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

function get.bitrate(self)
	return self._bitrate
end

function get.userLimit(self)
	return self._user_limit
end

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

function get.connection(self)
	return self._connection
end

return GuildVoiceChannel
