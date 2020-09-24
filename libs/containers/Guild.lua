local Snowflake = require('./Snowflake')

local json = require('json')
local class = require('../class')
local typing = require('../typing')
local helpers = require('../helpers')

local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize
local readOnly = helpers.readOnly

local Guild, get = class('Guild', Snowflake)

function Guild:__init(data, client)
	Snowflake.__init(self, data, client)
	return self:_load(data)
end

function Guild:_load(data)

	self._name = data.name -- http and wss
	self._icon = data.icon -- http and wss
	self._splash = data.splash -- http and wss
	self._discovery_splash = data.discovery_splash -- http and wss
	self._owner_id = data.owner_id -- http and wss
	self._region = data.region -- http and wss
	self._afk_channel_id = data.afk_channel_id -- http and wss
	self._afk_timeout = data.afk_timeout -- http and wss
	self._verification_level = data.verification_level -- http and wss
	self._default_message_notifications = data.default_message_notifications -- http and wss
	self._explicit_content_filter = data.explicit_content_filter -- http and wss
	self._features = data.features -- http and wss
	self._mfa_level = data.mfa_level -- http and wss
	self._application_id = data.application_id -- http and wss
	self._system_channel_id = data.system_channel_id -- http and wss
	self._system_channel_flags = data.system_channel_flags -- http and wss
	self._rules_channel_id = data.rules_channel_id -- http and wss
	self._vanity_url_code = data.vanity_url_code -- http and wss
	self._description = data.description -- http and wss
	self._banner = data.banner -- http and wss
	self._premium_tier = data.premium_tier -- http and wss
	self._premium_subscription_count = data.premium_subscription_count -- http and wss
	self._preferred_locale = data.preferred_locale -- http and wss
	self._public_updates_channel_id = data.public_updates_channel_id -- http and wss
	self._max_video_channel_users = data.max_video_channel_users -- http and wss

	self._owner = data.owner -- oauth only?
	self._permissions = data.permissions -- http only?

	self._max_members = data.max_members -- http and GUILD_UPDATE only
	self._max_presences = data.max_presences -- http and GUILD_UPDATE only
	self._widget_enabled = data.widget_enabled -- http and GUILD_UPDATE only
	self._widget_channel_id = data.widget_channel_id -- http and GUILD_UPDATE only

	self._approximate_member_count = data.approximate_member_count -- http "with_counts" only
	self._approximate_presence_count = data.approximate_presence_count -- http "with_counts" only

	-- TODO: data.roles and data.emojis
	-- TODO: gateway properties: joined_at, large, lazy, member_count
	-- TODO: gateway arrays: channels, members, presences, voice_states

end

-- TODO: requestMembers

function Guild:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Guild has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildIconURL(self.id, self.icon, ext, size)
end

function Guild:getBannerURL(ext, size)
	if not self.banner then
		return nil, 'Guild has no banner'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildBannerURL(self.id, self.banner, ext, size)
end

function Guild:getSplashURL(ext, size)
	if not self.splash then
		return nil, 'Guild has no splash'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildSplashURL(self.id, self.splash, ext, size)
end

function Guild:getDiscoverySplashURL(ext, size)
	if not self.discoverySplash then
		return nil, 'Guild has no discovery splash'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildDiscoverySplashURL(self.id, self.discoverySplash, ext, size)
end

function Guild:getMember(userId)
	return self.client:getGuildMember(self.id, userId)
end

function Guild:getEmoji(emojiId)
	return self.client:getGuildEmoji(self.id, emojiId)
end

function Guild:getMembers(limit, after)
	return self.client:getGuildMembers(self.id, limit, after)
end

function Guild:getRoles()
	return self.client:getGuildRoles(self.id)
end

function Guild:getEmojis()
	return self.client:getGuildEmojis(self.id)
end

function Guild:getChannels()
	return self.client:getGuildChannels(self.id)
end

function Guild:createRole(payload)
	return self.client:createGuildRole(self.id, payload)
end

function Guild:createEmoji(name, image)
	return self.client:createGuildEmoji(self.id, name, image)
end

function Guild:createChannel(payload)
	return self.client:createGuildChannel(self.id, payload)
end

function Guild:setName(name)
	return self.client:modifyGuild(self.id, {name = name or json.null})
end

function Guild:setRegion(region)
	return self.client:modifyGuild(self.id, {region = region or json.null})
end

function Guild:setVerificationLevel(verificationLevel)
	return self.client:modifyGuild(self.id, {verificationLevel = verificationLevel or json.null})
end

function Guild:setNotificationSetting(notificationSetting)
	return self.client:modifyGuild(self.id, {notificationSetting = notificationSetting or json.null})
end

function Guild:setExplicitContentLevel(explicitContentLevel)
	return self.client:modifyGuild(self.id, {explicitContentLevel = explicitContentLevel or json.null})
end

function Guild:setAFKTimeout(afkTimeout)
	return self.client:modifyGuild(self.id, {afkTimeout = afkTimeout or json.null})
end

function Guild:setAFKChannel(afkChannelId)
	return self.client:modifyGuild(self.id, {afkChannelId = afkChannelId or json.null})
end

function Guild:setSystemChannel(systemChannelId)
	return self.client:modifyGuild(self.id, {systemChannelId = systemChannelId or json.null})
end

function Guild:setRulesChannel(rulesChannelId)
	return self.client:modifyGuild(self.id, {rulesChannelId = rulesChannelId or json.null})
end

function Guild:setPublicUpdatesChannel(publicUpdatesChannelId)
	return self.client:modifyGuild(self.id, {publicUpdatesChannelId = publicUpdatesChannelId or json.null})
end

function Guild:setOwner(ownerId)
	return self.client:modifyGuild(self.id, {ownerId = ownerId or json.null})
end

function Guild:setIcon(icon)
	return self.client:modifyGuild(self.id, {icon = icon or json.null})
end

function Guild:setBanner(banner)
	return self.client:modifyGuild(self.id, {banner = banner or json.null})
end

function Guild:setSplash(splash)
	return self.client:modifyGuild(self.id, {splash = splash or json.null})
end

function Guild:setDiscoverySplash(discoverySplash)
	return self.client:modifyGuild(self.id, {discoverySplash = discoverySplash or json.null})
end

function Guild:setPreferredLocale(preferredLocale)
	return self.client:modifyGuild(self.id, {preferredLocale = preferredLocale or json.null})
end

function Guild:setDescription(description)
	return self.client:modifyGuild(self.id, {description = description or json.null})
end

function Guild:getPruneCount(days)
	return self.client:getGuildPruneCount(self.id, days)
end

function Guild:pruneMembers(payload)
	return self.client:pruneGuildMembers(self.id, payload)
end

function Guild:getBan(userId)
	return self.client:getGuildBan(self.id, userId)
end

function Guild:getBans()
	return self.client:getGuildBans(self.id)
end

function Guild:getInvites()
	return self.client:getGuildInvites(self.id)
end

function Guild:getWebhooks()
	return self.client:getGuildWebhooks(self.id)
end

function Guild:getAuditLogs(payload)
	return self.client:getGuildAuditLogs(self.id, payload)
end

function Guild:getVoiceRegions()
	-- TODO
end

function Guild:leave()
	return self.client:leaveGuild(self.id)
end

function Guild:delete()
	return self.client:deleteGuild(self.id)
end

function Guild:removeMember(userId, reason)
	return self.client:removeGuildMember(self.id, userId, reason)
end

function Guild:createBan(userId, reason, days)
	return self.client:createGuildBan(self.id, userId, reason, days)
end

function Guild:removeBan(userId, reason)
	return self.client:removeGuildBan(self.id, userId, reason)
end

----

function get:shardId() -- TODO
end

function get:joinedAt() -- TODO
end

function get:unavailable() -- TODO
end

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

function get:splash()
	return self._splash
end

function get:discoverySplash()
	return self._discovery_splash
end

function get:ownerId()
	return self._owner_id
end

function get:region()
	return self._region
end

function get:afkChannelId()
	return self._afk_channel_id
end

function get:afkTimeout()
	return self._afk_timeout
end

function get:verificationLevel()
	return self._verification_level
end

function get:notificationSetting()
	return self._default_message_notifications
end

function get:explicitContentSetting()
	return self._explicit_content_filter
end

function get:features()
	return readOnly(self._features)
end

function get:mfaLevel()
	return self._mfa_level
end

function get:applicationId()
	return self._application_id
end

function get:widgetEnabled()
	return self._widget_enabled
end

function get:widgetChannelId()
	return self._widget_channel_id
end

function get:systemChannelId()
	return self._system_channel_id
end

function get:systemChannelFlags()
	return self._system_channel_flags
end

function get:rulesChannelId()
	return self._rules_channel_id
end

function get:maxPresences()
	return self._max_presences
end

function get:maxMembers()
	return self._max_members
end

function get:vanityCode()
	return self._vanity_url_code
end

function get:description()
	return self._description
end

function get:banner()
	return self._banner
end

function get:premiumTier()
	return self._premium_tier
end

function get:premiumSubscriptionCount()
	return self._premium_subscription_count
end

function get:preferredLocale()
	return self._preferred_locale
end

function get:publicUpdatesChannelId()
	return self._public_updates_channel_id
end

function get:maxVideoChannelUsers()
	return self._max_video_channel_users
end

function get:approximateMemberCount()
	return self._approximate_member_count
end

function get:approximatePresenceCount()
	return self._approximate_presence_count
end

return Guild
