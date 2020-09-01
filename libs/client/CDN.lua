local class = require('../class')

local BASE_URL = "https://cdn.discordapp.com"

local endpoints = {
	CUSTOM_EMOJI           = "/emojis/%s",
	GUILD_ICON             = "/icons/%s/%s",
	GUILD_SPLASH           = "/splashes/%s/%s",
	GUILD_DISCOVERY_SPLASH = "/discovery-splashes/%s/%s",
	GUILD_BANNER           = "/banners/%s/%s",
	DEFAULT_USER_AVATAR    = "/embed/avatars/%s",
	USER_AVATAR            = "/avatars/%s/%s",
	APPLICATION_ICON       = "/app-icons/%s/%s",
	APPLICATION_ASSET      = "/app-assets/%s/%s",
	ACHIEVEMENT_ICON       = "/app-assets/%s/achievements/%s/icons/%s",
	TEAM_ICON              = "/team-icons/%s/%s",
}

local CDN = class('CDN')

function CDN:__init(client)
	self.client = assert(client)
end

function CDN:buildURL(endpoint, params, ext, size)

	local options = self.client:getOptions()

	endpoint = endpoint:format(unpack(params))
	ext = ext or options.defaultImageExtension
	size = size or options.defaultImageSize

	return BASE_URL .. endpoint .. '.' .. ext .. '?size=' .. size

end

function CDN:getCustomEmojiURL(emoji_id, ext, size)
	return self:buildURL(endpoints.CUSTOM_EMOJI, {emoji_id}, ext, size)
end

function CDN:getGuildIconURL(guild_id, icon, ext, size)
	return self:buildURL(endpoints.GUILD_ICON, {guild_id, icon}, ext, size)
end

function CDN:getGuildSplashURL(guild_id, splash, ext, size)
	return self:buildURL(endpoints.GUILD_SPLASH, {guild_id, splash}, ext, size)
end

function CDN:getGuildDiscoverySplashURL(guild_id, discovery_splash, ext, size)
	return self:buildURL(endpoints.GUILD_DISCOVERY_SPLASH, {guild_id, discovery_splash}, ext, size)
end

function CDN:getGuildBannerURL(guild_id, banner, ext, size)
	return self:buildURL(endpoints.GUILD_BANNER, {guild_id, banner}, ext, size)
end

function CDN:getDefaultUserAvatarURL(default_avatar, ext, size)
	return self:buildURL(endpoints.DEFAULT_USER_AVATAR, {default_avatar}, ext, size)
end

function CDN:getUserAvatarURL(user_id, avatar, ext, size)
	return self:buildURL(endpoints.USER_AVATAR, {user_id, avatar}, ext, size)
end

function CDN:getApplicationIconURL(application_id, icon, ext, size)
	return self:buildURL(endpoints.APPLICATION_ICON, {application_id, icon}, ext, size)
end

function CDN:getApplicationAssetURL(application_id, asset_id, ext, size)
	return self:buildURL(endpoints.APPLICATION_ASSET, {application_id, asset_id}, ext, size)
end

function CDN:getAchievementIconURL(application_id, achievement_id, icon_hash, ext, size)
	return self:buildURL(endpoints.ACHIEVEMENT_ICON, {application_id, achievement_id, icon_hash}, ext, size)
end

function CDN:getTeamIconURL(team_id, team_icon, ext, size)
	return self:buildURL(endpoints.TEAM_ICON, {team_id, team_icon}, ext, size)
end

return CDN
