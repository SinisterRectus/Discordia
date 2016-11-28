local GuildChannel = require('./GuildChannel')

local clamp = math.clamp

local GuildVoiceChannel, property = class('GuildVoiceChannel', GuildChannel)
GuildVoiceChannel.__description = "Represents a Discord guild voice channel."

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	GuildVoiceChannel._update(self, data)
end

function GuildVoiceChannel:_update(data)
	GuildChannel._update(self, data)
end

local function setBitrate(self, bitrate)
	bitrate = bitrate and clamp(bitrate, 8000, self._parent._vip and 128000 or 96000) or 64000
	local success, data = self._parent._parent._api:modifyChannel(self._id, {bitrate = bitrate})
	if success then self._bitrate = data.bitrate end
	return success
end

local function setUserLimit(self, limit)
	limit = limit and clamp(limit, 0, 99) or 0
	local success, data = self._parent._parent._api:modifyChannel(self._id, {user_limit = limit})
	if success then self._user_limit = data.user_limit end
	return success
end

property('bitrate', '_bitrate', setBitrate, '[number]', "Channel bitrate in bits per seconds (8000 to 96000 or 128000 for VIP guilds, default: 64000)")
property('userLimit', '_user_limit', setUserLimit, '[number]', "Limit to the number of users allowed in the channel (use 0 for infinite, default: 0)")

return GuildVoiceChannel
