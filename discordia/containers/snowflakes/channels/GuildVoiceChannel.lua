local GuildChannel = require('./GuildChannel')

local clamp = math.clamp

local GuildVoiceChannel, get, set = class('GuildVoiceChannel', GuildChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	GuildVoiceChannel._update(self, data)
end

get('bitrate', '_bitrate')
get('userLimit', '_user_limit')

function GuildVoiceChannel:_update(data)
	GuildChannel._update(self, data)
end

set('bitrate', function(self, bitrate)
	bitrate = bitrate and clamp(bitrate, 8000, self._parent._vip and 128000 or 96000) or 64000
	local success, data = self.client._api:modifyChannel(self._id, {bitrate = bitrate})
	if success then self._bitrate = data.bitrate end
	return success
end)

set('limit', function(self, limit)
	limit = limit and clamp(limit, 0, 99) or 0
	local success, data = self.client._api:modifyChannel(self._id, {user_limit = limit})
	if success then self._user_limit = data.user_limit end
	return success
end)

return GuildVoiceChannel
