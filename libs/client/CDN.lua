local class = require('../class')
local constants = require('../constants')

local CDN_BASE_URL = constants.CDN_BASE_URL

local endpoints = {
	CUSTOM_EMOJI           = "/emojis/%s",
	GUILD_ICON             = "/icons/%s/%s",
	GUILD_SPLASH           = "/splashes/%s/%s",
	GUILD_DISCOVERY_SPLASH = "/discovery-splashes/%s/%s",
	GUILD_BANNER           = "/banners/%s/%s",
	USER_BANNER            = "/banners/%s/%s",
	DEFAULT_USER_AVATAR    = "/embed/avatars/%s",
	USER_AVATAR            = "/avatars/%s/%s",
	GUILD_MEMBER_AVATAR    = "/guilds/%s/users/%s/avatars/%s",
	APPLICATION_ICON       = "/app-icons/%s/%s",
	APPLICATION_COVER      = "/app-icons/%s/%s",
	APPLICATION_ASSET      = "/app-assets/%s/%s",
	ACHIEVEMENT_ICON       = "/app-assets/%s/achievements/%s/icons/%s",
	TEAM_ICON              = "/team-icons/%s/%s",
	ROLE_ICON              = "/role-icons/%s/%s",
}

local CDN = class('CDN')

function CDN:__init(client)
	self._client = assert(client)
end

function CDN:buildURL(endpoint, ext, size)
	local client = self._client
	ext = ext or client.defaultImageExtension
	size = size or client.defaultImageSize
	return CDN_BASE_URL .. endpoint .. '.' .. ext .. '?size=' .. size
end

function CDN:getCustomEmojiURL(emoji_id, ext, size)
	return self:buildURL(endpoints.CUSTOM_EMOJI:format(emoji_id), ext, size)
end

function CDN:getGuildIconURL(guild_id, icon, ext, size)
	return self:buildURL(endpoints.GUILD_ICON:format(guild_id, icon), ext, size)
end

function CDN:getGuildSplashURL(guild_id, splash, ext, size)
	return self:buildURL(endpoints.GUILD_SPLASH:format(guild_id, splash), ext, size)
end

function CDN:getGuildDiscoverySplashURL(guild_id, discovery_splash, ext, size)
	return self:buildURL(endpoints.GUILD_DISCOVERY_SPLASH:format(guild_id, discovery_splash), ext, size)
end

function CDN:getGuildBannerURL(guild_id, banner, ext, size)
	return self:buildURL(endpoints.GUILD_BANNER:format(guild_id, banner), ext, size)
end

function CDN:getUserBannerURL(user_id, banner, ext, size)
	return self:buildURL(endpoints.USER_BANNER:format(user_id, banner), ext, size)
end

function CDN:getDefaultUserAvatarURL(default_avatar, ext, size)
	return self:buildURL(endpoints.DEFAULT_USER_AVATAR:format(default_avatar), ext, size)
end

function CDN:getUserAvatarURL(user_id, avatar, ext, size)
	return self:buildURL(endpoints.USER_AVATAR:format(user_id, avatar), ext, size)
end

function CDN:getGuildMemberAvatarURL(guild_id, user_id, avatar, ext, size)
	return self:buildURL(endpoints.GUILD_MEMBER_AVATAR:format(guild_id, user_id, avatar), ext, size)
end

function CDN:getApplicationIconURL(application_id, icon, ext, size)
	return self:buildURL(endpoints.APPLICATION_ICON:format(application_id, icon), ext, size)
end

function CDN:getApplicationCoverURL(application_id, cover_image, ext, size)
	return self:buildURL(endpoints.APPLICATION_COVER:format(application_id, cover_image), ext, size)
end

function CDN:getApplicationAssetURL(application_id, asset_id, ext, size)
	return self:buildURL(endpoints.APPLICATION_ASSET:format(application_id, asset_id), ext, size)
end

function CDN:getAchievementIconURL(application_id, achievement_id, icon_hash, ext, size)
	return self:buildURL(endpoints.ACHIEVEMENT_ICON:format(application_id, achievement_id, icon_hash), ext, size)
end

function CDN:getTeamIconURL(team_id, team_icon, ext, size)
	return self:buildURL(endpoints.TEAM_ICON:format(team_id, team_icon), ext, size)
end

function CDN:getRoleIconURL(role_id, role_icon, ext, size)
	return self:buildURL(endpoints.ROLE_ICON:format(role_id, role_icon), ext, size)
end

return CDN
