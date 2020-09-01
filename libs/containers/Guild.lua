local Snowflake = require('./Snowflake')
local AuditLogEntry = require('./AuditLogEntry')
local Ban = require('./Ban')
local Channel = require('./Channel')
local Emoji = require('./Emoji')
local Invite = require('./Invite')
local Member = require('./Member')
local Role = require('./Role')
local Webhook = require('./Webhook')

local json = require('json')
local class = require('../class')
local typing = require('../typing')
local enums = require('../enums')

local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize
local checkSnowflake, checkInteger = typing.checkSnowflake, typing.checkInteger
local checkType, checkEnum = typing.checkType, typing.checkEnum
local checkImageData = typing.checkImageData

local Guild, get = class('Guild', Snowflake)

function Guild:__init(data, client)
	Snowflake.__init(self, data, client)
	return self:_load(data)
end

function Guild:_load(data)
	self._name = data.name
	self._icon = data.icon
	self._splash = data.splash
	self._discovery_splash = data.discovery_splash
	self._owner = data.owner
	self._owner_id = data.owner_id
	self._permissions = data.permissions
	self._region = data.region
	self._afk_channel_id = data.afk_channel_id
	self._afk_timeout = data.afk_timeout
	self._embed_enabled = data.embed_enabled
	self._embed_channel_id = data.embed_channel_id
	self._verification_level = data.verification_level
	self._default_message_notifications = data.default_message_notifications
	self._explicit_content_filter = data.explicit_content_filter
	self._features = data.features -- raw table
	self._mfa_level = data.mfa_level
	self._application_id = data.application_id
	self._widget_enabled = data.widget_enabled
	self._widget_channel_id = data.widget_channel_id
	self._system_channel_id = data.system_channel_id
	self._system_channel_flags = data.system_channel_flags
	self._rules_channel_id = data.rules_channel_id
	self._max_presences = data.max_presences
	self._max_members = data.max_members
	self._vanity_url_code = data.vanity_url_code
	self._description = data.description
	self._banner = data.banner
	self._premium_tier = data.premium_tier
	self._premium_subscription_count = data.premium_subscription_count
	self._preferred_locale = data.preferred_locale
	self._public_updates_channel_id = data.public_updates_channel_id
	self._max_video_channel_users = data.max_video_channel_users
	self._approximate_member_count = data.approximate_member_count
	self._approximate_presence_count = data.approximate_presence_count
	-- TODO: data.roles and data.emojis
	-- TODO: GUILD_CREATE properties
end

function Guild:_modify(payload)
	local data, err = self.client.api:modifyGuild(self.id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Guild:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Guild has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.cdn:getGuildIconURL(self.id, self.icon, ext, size)
end

function Guild:getBannerURL(ext, size)
	if not self.banner then
		return nil, 'Guild has no banner'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.cdn:getGuildBannerURL(self.id, self.banner, ext, size)
end

function Guild:getSplashURL(ext, size)
	if not self.splash then
		return nil, 'Guild has no splash'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.cdn:getGuildSplashURL(self.id, self.splash, ext, size)
end

function Guild:getDiscoverySplashURL(ext, size)
	if not self.discoverySplash then
		return nil, 'Guild has no discovery splash'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.cdn:getGuildDiscoverySplashURL(self.id, self.discoverySplash, ext, size)
end

function Guild:getMember(userId)
	local data, err = self.client.api:getGuildMember(self.id, checkSnowflake(userId))
	if data then
		data.guild_id = self.id
		return Member(data, self.client)
	else
		return nil, err
	end
end

function Guild:getEmoji(emojiId)
	local data, err = self.client.api:getGuildEmoji(self.id, checkSnowflake(emojiId))
	if data then
		data.guild_id = self.id
		return Emoji(data, self.client)
	else
		return nil, err
	end
end

function Guild:getMembers(limit, after)
	local query = {
		limit = limit and checkInteger(limit),
		after = after and checkSnowflake(after),
	}
	local data, err = self.client.api:listGuildMembers(self.id, query)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Member(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getRoles()
	local data, err = self.client.api:getGuildRoles(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Role(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getEmojis()
	local data, err = self.client.api:listGuildEmojis(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Emoji(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getChannels()
	local data, err = self.client.api:getGuildChannels(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Channel(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:createRole(payload)
	local data, err
	if type(payload) == 'table' then
		data, err = self.client.api:createGuildRole(self.id, {
			name = checkType('string', payload.name),
			permissions = payload.permissions and checkInteger(payload.permissions),
			color = payload.color and checkInteger(payload.color),
			hoist = payload.hoist ~= nil and checkType('boolean', payload.hoist),
			mentionable = payload.mentionable ~= nil and checkType('boolean', payload.mentionable),
		})
	else
		data, err = self.client.api:createGuildRole(self.id, {name = checkType('string', payload)})
	end
	if data then
		data.guild_id = self.id
		return Role(data, self.client)
	else
		return nil, err
	end
end

function Guild:createEmoji(name, image)
	local data, err = self.client.api:createGuildEmoji(self.id, {
		name = checkType('string', name),
		image = checkImageData(image),
	})
	if data then
		data.guild_id = self.id
		return Emoji(data, self.client)
	else
		return nil, err
	end
end

function Guild:createChannel(payload)
	local data, err
	if type(payload) == 'table' then
		data, err = self.client.api:createGuildChannel(self.id, {
			name = checkType('string', payload.name),
			type = payload.type and checkEnum(enums.channelType, payload.type),
			topic = payload.topic and checkType('string', payload.topic),
			nsfw = payload.nsfw ~= nil and checkType('boolean', payload.nsfw),
		})
	else
		data, err = self.client.api:createGuildChannel(self.id, {name = checkType('string', payload)})
	end
	if data then
		data.guild_id = self.id
		return Channel(data, self.client)
	else
		return nil, err
	end
end

function Guild:setName(name)
	return self:_modify {name = name and checkType('string', name) or json.null}
end

function Guild:setRegion(region)
	return self:_modify {region = region and checkType('string', region) or json.null}
end

function Guild:setVerificationLevel(level)
	return self:_modify {verification_level = level and checkEnum(enums.verificationLevel, level) or json.null}
end

function Guild:setNotificationSetting(setting)
	return self:_modify {default_message_notifications = setting and checkEnum(enums.notificationSetting, setting) or json.null}
end

function Guild:setExplicitContentLevel(level)
	return self:_modify {explicit_content_filter = level and checkEnum(enums.explicitContentLevel, level) or json.null}
end

function Guild:setAFKTimeout(timeout)
	return self:_modify {afk_timeout = timeout and checkType('number', timeout) or json.null}
end

function Guild:setAFKChannel(id)
	return self:_modify {afk_channel_id = id and checkSnowflake(id) or json.null}
end

function Guild:setSystemChannel(id)
	return self:_modify {system_channel_id = id and checkSnowflake(id) or json.null}
end

function Guild:setRulesChannel(id)
	return self:_modify {rules_channel_id = id and checkSnowflake(id) or json.null}
end

function Guild:setPublicUpdatesChannel(id)
	return self:_modify {public_updates_channel_id = id and checkSnowflake(id) or json.null}
end

function Guild:setOwner(id)
	return self:_modify {owner_id = id and checkSnowflake(id) or json.null}
end

function Guild:setIcon(icon)
	return self:_modify {icon = icon and checkImageData(icon) or json.null}
end

function Guild:setBanner(banner)
	return self:_modify {banner = banner and checkImageData(banner) or json.null}
end

function Guild:setSplash(splash)
	return self:_modify {splash = splash and checkImageData(splash) or json.null}
end

function Guild:setDiscoverySplash(splash)
	return self:_modify {discovery_splash = splash and checkImageData(splash) or json.null}
end

function Guild:getPruneCount(days)
	local query = days and {days = checkInteger(days)} or nil
	local data, err = self.client.api:getGuildPruneCount(self.id, query)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

function Guild:pruneMembers(payload)
	local data, err
	if type(payload) == 'table' then
		data, err = self.client.api:beginGuildPrune(self.id, {
			days = payload.days and checkInteger(payload.days),
			compute_prune_count = payload.compute ~= nil and checkType('boolean', payload.compute),
		})
	else
		data, err = self.client.api:beginGuildPrune(self.id)
	end
	if data then
		return data.pruned
	else
		return nil, err
	end
end

function Guild:getBan(userId)
	local data, err = self.client.api:getGuildBan(self.id, checkSnowflake(userId))
	if data then
		data.guild_id = self.id
		return Ban(data, self.client)
	else
		return nil, err
	end
end

function Guild:getBans()
	local data, err = self.client.api:getGuildBans(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Ban(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getInvites()
	local data, err = self.client.api:getGuildInvites(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Invite(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getWebhooks()
	local data, err = self.client.api:getGuildWebhooks(self.id)
	if data then
		for i, v in ipairs(data) do
			v.guild_id = self.id
			data[i] = Webhook(v, self.client)
		end
		return data
	else
		return nil, err
	end
end

function Guild:getAuditLogs(payload)
	payload = checkType('table', payload)
	local data, err = self.client.api:getGuildAuditLog(self.id, {
		limit = checkInteger(payload.limit),
		user_id = checkSnowflake(payload.userId),
		before = checkSnowflake(payload.before),
		action_type = checkEnum(enums.actionType, payload.actionType),
	})
	if data then
		for i, v in ipairs(data.audit_log_entries) do
			v.guild_id = self.id
			data.audit_log_entries[i] = AuditLogEntry(v, self.client)
		end
		-- TODO: users and webhooks
		return data.audit_log_entries
	else
		return nil, err
	end
end

function Guild:getVoiceRegions()
	return self.client.api:getGuildVoiceRegions() -- raw table
end

function Guild:leave()
	local data, err = self.client.api:leaveGuild(self.id)
	if data then
		return true
	else
		return false, err
	end
end

function Guild:delete()
	local data, err = self.client.api:deleteGuild(self.id)
	if data then
		return true
	else
		return false, err
	end
end

function Guild:kickUser(userId, reason)
	local query = reason and {reason = checkType('string', reason)} or nil
	local data, err = self.client.api:removeGuildMember(self.id, checkSnowflake(userId), query)
	if data then
		return true
	else
		return false, err
	end
end

function Guild:banUser(userId, reason, days)
	local query = {
		reason = reason and checkType('string', reason),
		delete_message_days = days and checkInteger(days),
	}
	local data, err = self.client.api:createGuildBan(self.id, checkSnowflake(userId), query)
	if data then
		return true
	else
		return false, err
	end
end

function Guild:unbanUser(userId, reason)
	local query = reason and {reason = checkType('string', reason)} or nil
	local data, err = self.client.api:removeGuildBan(self.id, checkSnowflake(userId), query)
	if data then
		return true
	else
		return false, err
	end
end

----

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

function get:owner() -- boolean for current user, not the owner object
	return self._owner
end

function get:ownerId()
	return self._owner_id
end

function get:permissions()
	return self._permissions
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

function get:embedEnabled()
	return self._embed_enabled
end

function get:embedChannelId()
	return self._embed_channel_id
end

function get:verificationLevel()
	return self._verification_level
end

function get:notificationSetting()
	return self._default_message_notifications
end

function get:explicitContentFilter()
	return self._explicit_content_filter
end

function get:features()
	return self._features
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
