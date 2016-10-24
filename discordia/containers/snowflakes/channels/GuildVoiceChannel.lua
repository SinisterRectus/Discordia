local GuildChannel = require('./GuildChannel')
local VoiceChannel = require('./VoiceChannel')

local GuildVoiceChannel = class('GuildVoiceChannel', GuildChannel, VoiceChannel)

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	VoiceChannel.__init(self, data, parent)
	GuildVoiceChannel.update(self, data)
end

function GuildVoiceChannel:update(data)
	GuildChannel.update(self, data)
	VoiceChannel.update(self, data)
end

function GuildVoiceChannel:setBitrate(bitrate)
	bitrate = math.clamp(bitrate, 8000, self.parent.vip and 128000 or 96000)
	local success, data = self.client.api:modifyChannel(self.id, {bitrate = bitrate})
	if success then self.bitrate = data.bitrate end
	return success
end

function GuildVoiceChannel:setUserLimit(limit)
	limit = math.clamp(limit, 0, 99)
	local success, data = self.client.api:modifyChannel(self.id, {user_limit = limit})
	if success then self.userLimit = data.user_limit end
	return success
end

function GuildVoiceChannel:clearUserLimit()
	return self:setUserLimit(0)
end

return GuildVoiceChannel
