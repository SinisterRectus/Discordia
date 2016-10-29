local GuildChannel = require('./GuildChannel')
local VoiceChannel = require('./VoiceChannel')

local clamp = math.clamp

local GuildVoiceChannel = class('GuildVoiceChannel', GuildChannel, VoiceChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	VoiceChannel.__init(self, data, parent)
	GuildVoiceChannel._update(self, data)
end

function GuildVoiceChannel:_update(data)
	GuildChannel._update(self, data)
	VoiceChannel._update(self, data)
end

function GuildVoiceChannel:setBitrate(bitrate)
	bitrate = clamp(bitrate, 8000, self.parent.vip and 128000 or 96000)
	local success, data = self.client.api:modifyChannel(self.id, {bitrate = bitrate})
	if success then self.bitrate = data.bitrate end
	return success
end

function GuildVoiceChannel:setUserLimit(limit)
	limit = clamp(limit, 0, 99)
	local success, data = self.client.api:modifyChannel(self.id, {user_limit = limit})
	if success then self.userLimit = data.user_limit end
	return success
end

function GuildVoiceChannel:clearUserLimit()
	return self:setUserLimit(0)
end

return GuildVoiceChannel
