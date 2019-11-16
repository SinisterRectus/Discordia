--[=[
@c Guild x Snowflake
@d Represents a Discord guild (or server). Guilds are a collection of members,
channels, and roles that represents one community.
]=]

local Cache = require('iterables/Cache')
local Role = require('containers/Role')
local Emoji = require('containers/Emoji')
local Invite = require('containers/Invite')
local Webhook = require('containers/Webhook')
local Ban = require('containers/Ban')
local Member = require('containers/Member')
local Resolver = require('client/Resolver')
local AuditLogEntry = require('containers/AuditLogEntry')
local GuildTextChannel = require('containers/GuildTextChannel')
local GuildVoiceChannel = require('containers/GuildVoiceChannel')
local GuildCategoryChannel = require('containers/GuildCategoryChannel')
local Snowflake = require('containers/abstract/Snowflake')

local json = require('json')
local enums = require('enums')

local channelType = enums.channelType
local floor = math.floor
local format = string.format

local Guild, get = require('class')('Guild', Snowflake)

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._roles = Cache({}, Role, self)
	self._emojis = Cache({}, Emoji, self)
	self._members = Cache({}, Member, self)
	self._text_channels = Cache({}, GuildTextChannel, self)
	self._voice_channels = Cache({}, GuildVoiceChannel, self)
	self._categories = Cache({}, GuildCategoryChannel, self)
	self._voice_states = {}
	if not data.unavailable then
		return self:_makeAvailable(data)
	end
end

function Guild:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Guild:_loadMore(data)
	if data.features then
		self._features = data.features
	end
end

function Guild:_makeAvailable(data)

	self._roles:_load(data.roles)
	self._emojis:_load(data.emojis)
	self:_loadMore(data)

	if not data.channels then return end -- incomplete guild

	local states = self._voice_states
	for _, state in ipairs(data.voice_states) do
		states[state.user_id] = state
	end

	local text_channels = self._text_channels
	local voice_channels = self._voice_channels
	local categories = self._categories

	for _, channel in ipairs(data.channels) do
		local t = channel.type
		if t == channelType.text or t == channelType.news then
			text_channels:_insert(channel)
		elseif t == channelType.voice then
			voice_channels:_insert(channel)
		elseif t == channelType.category then
			categories:_insert(channel)
		end
	end

	return self:_loadMembers(data)

end

function Guild:_loadMembers(data)
	local members = self._members
	members:_load(data.members)
	for _, presence in ipairs(data.presences) do
		local member = members:get(presence.user.id)
		if member then -- rogue presence check
			member:_loadPresence(presence)
		end
	end
	if self._large and self.client._options.cacheAllMembers then
		return self:requestMembers()
	end
end

function Guild:_modify(payload)
	local data, err = self.client._api:modifyGuild(self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[=[
@m requestMembers
@t ws
@r boolean
@d Asynchronously loads all members for this guild. You do not need to call this
if the `cacheAllMembers` client option (and the `syncGuilds` option for
user-accounts) is enabled on start-up.
]=]
function Guild:requestMembers()
	local shard = self.client._shards[self.shardId]
	if not shard then
		return false, 'Invalid shard'
	end
	if shard._loading then
		shard._loading.chunks[self._id] = true
	end
	return shard:requestGuildMembers(self._id)
end

--[=[
@m sync
@t ws
@r boolean
@d Asynchronously loads certain data and enables the receiving of certain events
for this guild. You do not need to call this if the `syncGuilds` client option
is enabled on start-up.

Note: This is only for user accounts. Bot accounts never need to sync guilds!
]=]
function Guild:sync()
	local shard = self.client._shards[self.shardId]
	if not shard then
		return false, 'Invalid shard'
	end
	if shard._loading then
		shard._loading.syncs[self._id] = true
	end
	return shard:syncGuilds({self._id})
end

--[=[
@m getMember
@t http?
@p id User-ID-Resolvable
@r Member
@d Gets a member object by ID. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made.
]=]
function Guild:getMember(id)
	id = Resolver.userId(id)
	local member = self._members:get(id)
	if member then
		return member
	else
		local data, err = self.client._api:getGuildMember(self._id, id)
		if data then
			return self._members:_insert(data)
		else
			return nil, err
		end
	end
end

--[=[
@m getRole
@t mem
@p id Role-ID-Resolvable
@r Role
@d Gets a role object by ID.
]=]
function Guild:getRole(id)
	id = Resolver.roleId(id)
	return self._roles:get(id)
end

--[=[
@m getEmoji
@t mem
@p id Emoji-ID-Resolvable
@r Emoji
@d Gets a emoji object by ID.
]=]
function Guild:getEmoji(id)
	id = Resolver.emojiId(id)
	return self._emojis:get(id)
end

--[=[
@m getChannel
@t mem
@p id Channel-ID-Resolvable
@r GuildChannel
@d Gets a text, voice, or category channel object by ID.
]=]
function Guild:getChannel(id)
	id = Resolver.channelId(id)
	return self._text_channels:get(id) or self._voice_channels:get(id) or self._categories:get(id)
end

--[=[
@m createTextChannel
@t http
@p name string
@r GuildTextChannel
@d Creates a new text channel in this guild. The name must be between 2 and 100
characters in length.
]=]
function Guild:createTextChannel(name)
	local data, err = self.client._api:createGuildChannel(self._id, {name = name, type = channelType.text})
	if data then
		return self._text_channels:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m createVoiceChannel
@t http
@p name string
@r GuildVoiceChannel
@d Creates a new voice channel in this guild. The name must be between 2 and 100
characters in length.
]=]
function Guild:createVoiceChannel(name)
	local data, err = self.client._api:createGuildChannel(self._id, {name = name, type = channelType.voice})
	if data then
		return self._voice_channels:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m createCategory
@t http
@p name string
@r GuildCategoryChannel
@d Creates a channel category in this guild. The name must be between 2 and 100
characters in length.
]=]
function Guild:createCategory(name)
	local data, err = self.client._api:createGuildChannel(self._id, {name = name, type = channelType.category})
	if data then
		return self._categories:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m createRole
@t http
@p name string
@r Role
@d Creates a new role in this guild. The name must be between 1 and 100 characters
in length.
]=]
function Guild:createRole(name)
	local data, err = self.client._api:createGuildRole(self._id, {name = name})
	if data then
		return self._roles:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m createEmoji
@t http
@p name string
@p image Base64-Resolvable
@r Emoji
@d Creates a new emoji in this guild. The name must be between 2 and 32 characters
in length. The image must not be over 256kb, any higher will return a 400 Bad Request
]=]
function Guild:createEmoji(name, image)
	image = Resolver.base64(image)
	local data, err = self.client._api:createGuildEmoji(self._id, {name = name, image = image})
	if data then
		return self._emojis:_insert(data)
	else
		return nil, err
	end
end

--[=[
@m setName
@t http
@p name string
@r boolean
@d Sets the guilds name. This must be between 2 and 100 characters in length.
]=]
function Guild:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setRegion
@t http
@p region string
@r boolean
@d Sets the guild's voice region (eg: `us-east`). See `listVoiceRegions` for a list
of acceptable regions.
]=]
function Guild:setRegion(region)
	return self:_modify({region = region or json.null})
end

--[=[
@m setVerificationLevel
@t http
@p verification_level number
@r boolean
@d Sets the guild's verification level setting. See the `verificationLevel`
enumeration for acceptable values.
]=]
function Guild:setVerificationLevel(verification_level)
	return self:_modify({verification_level = verification_level or json.null})
end

--[=[
@m setNotificationSetting
@t http
@p default_message_notifications number
@r boolean
@d Sets the guild's default notification setting. See the `notficationSetting`
enumeration for acceptable values.
]=]
function Guild:setNotificationSetting(default_message_notifications)
	return self:_modify({default_message_notifications = default_message_notifications or json.null})
end

--[=[
@m setExplicitContentSetting
@t http
@p explicit_content_filter number
@r boolean
@d Sets the guild's explicit content level setting. See the `explicitContentLevel`
enumeration for acceptable values.
]=]
function Guild:setExplicitContentSetting(explicit_content_filter)
	return self:_modify({explicit_content_filter = explicit_content_filter or json.null})
end

--[=[
@m setAFKTimeout
@t http
@p afk_timeout number
@r number
@d Sets the guild's AFK timeout in seconds.
]=]
function Guild:setAFKTimeout(afk_timeout)
	return self:_modify({afk_timeout = afk_timeout or json.null})
end

--[=[
@m setAFKChannel
@t http
@p id Channel-ID-Resolvable
@r boolean
@d Sets the guild's AFK channel.
]=]
function Guild:setAFKChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({afk_channel_id = id or json.null})
end

--[=[
@m setSystemChannel
@t http
@p id Channel-Id-Resolvable
@r boolean
@d Sets the guild's join message channel.
]=]
function Guild:setSystemChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({system_channel_id = id or json.null})
end

--[=[
@m setOwner
@t http
@p id User-ID-Resolvable
@r boolean
@d Transfers ownership of the guild to another user. Only the current guild owner
can do this.
]=]
function Guild:setOwner(id)
	id = id and Resolver.userId(id)
	return self:_modify({owner_id = id or json.null})
end

--[=[
@m setIcon
@t http
@p icon Base64-Resolvable
@r boolean
@d Sets the guild's icon. To remove the icon, pass `nil`.
]=]
function Guild:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[=[
@m setBanner
@t http
@p banner Base64-Resolvable
@r boolean
@d Sets the guild's banner. To remove the banner, pass `nil`.
]=]
function Guild:setBanner(banner)
	banner = banner and Resolver.base64(banner)
	return self:_modify({banner = banner or json.null})
end

--[=[
@m setSplash
@t http
@p splash Base64-Resolvable
@r boolean
@d Sets the guild's splash. To remove the splash, pass `nil`.
]=]
function Guild:setSplash(splash)
	splash = splash and Resolver.base64(splash)
	return self:_modify({splash = splash or json.null})
end

--[=[
@m getPruneCount
@t http
@op days number
@r number
@d Returns the number of members that would be pruned from the guild if a prune
were to be executed.
]=]
function Guild:getPruneCount(days)
	local data, err = self.client._api:getGuildPruneCount(self._id, days and {days = days} or nil)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

--[=[
@m pruneMembers
@t http
@op days number
@op count boolean
@r number
@d Prunes (removes) inactive, roleless members from the guild who have not been online in the last provided days.
If the `count` boolean is provided, the number of pruned members is returned; otherwise, `0` is returned.
]=]
function Guild:pruneMembers(days, count)
	local t1 = type(days)
	if t1 == 'number' then
		count = type(count) == 'boolean' and count
	elseif t1 == 'boolean' then
		count = days
		days = nil
	end
	local data, err = self.client._api:beginGuildPrune(self._id, nil, {
		days = days,
		compute_prune_count = count,
	})
	if data then
		return data.pruned
	else
		return nil, err
	end
end

--[=[
@m getBans
@t http
@r Cache
@d Returns a newly constructed cache of all ban objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]=]
function Guild:getBans()
	local data, err = self.client._api:getGuildBans(self._id)
	if data then
		return Cache(data, Ban, self)
	else
		return nil, err
	end
end

--[=[
@m getBan
@t http
@p id User-ID-Resolvable
@r Ban
@d This will return a Ban object for a giver user if that user is banned
from the guild; otherwise, `nil` is returned.
]=]
function Guild:getBan(id)
	id = Resolver.userId(id)
	local data, err = self.client._api:getGuildBan(self._id, id)
	if data then
		return Ban(data, self._parent)
	else
		return nil, err
	end
end

--[=[
@m getInvites
@t http
@r Cache
@d Returns a newly constructed cache of all invite objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]=]
function Guild:getInvites()
	local data, err = self.client._api:getGuildInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

--[=[
@m getAuditLogs
@t http
@op query table
@r Cache
@d Returns a newly constructed cache of audit log entry objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.

If included, the query parameters include: query.limit: number, query.user: UserId Resolvable
query.before: EntryId Resolvable, query.type: ActionType Resolvable
]=]
function Guild:getAuditLogs(query)
	if type(query) == 'table' then
		query = {
			limit = query.limit,
			user_id = Resolver.userId(query.user),
			before = Resolver.entryId(query.before),
			action_type = Resolver.actionType(query.type),
		}
	end
	local data, err = self.client._api:getGuildAuditLog(self._id, query)
	if data then
		self.client._users:_load(data.users)
		self.client._webhooks:_load(data.webhooks)
		return Cache(data.audit_log_entries, AuditLogEntry, self)
	else
		return nil, err
	end
end

--[=[
@m getWebhooks
@t http
@r Cache
@d Returns a newly constructed cache of all webhook objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]=]
function Guild:getWebhooks()
	local data, err = self.client._api:getGuildWebhooks(self._id)
	if data then
		return Cache(data, Webhook, self.client)
	else
		return nil, err
	end
end

--[=[
@m listVoiceRegions
@t http
@r table
@d Returns a raw data table that contains a list of available voice regions for
this guild, as provided by Discord, with no additional parsing.
]=]
function Guild:listVoiceRegions()
	return self.client._api:getGuildVoiceRegions(self._id)
end

--[=[
@m leave
@t http
@r boolean
@d Removes the current user from the guild.
]=]
function Guild:leave()
	local data, err = self.client._api:leaveGuild(self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the guild. The current user must owner the server. This cannot be undone!
]=]
function Guild:delete()
	local data, err = self.client._api:deleteGuild(self._id)
	if data then
		local cache = self._parent._guilds
		if cache then
			cache:_delete(self._id)
		end
		return true
	else
		return false, err
	end
end

--[=[
@m kickUser
@t http
@p id User-ID-Resolvable
@op reason string
@r boolean
@d Kicks a user/member from the guild with an optional reason.
]=]
function Guild:kickUser(id, reason)
	id = Resolver.userId(id)
	local query = reason and {reason = reason}
	local data, err = self.client._api:removeGuildMember(self._id, id, query)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m banUser
@t http
@p id User-ID-Resolvable
@op reason string
@op days number
@r boolean
@d Bans a user/member from the guild with an optional reason. The `days` parameter
is the number of days to consider when purging messages, up to 7.
]=]
function Guild:banUser(id, reason, days)
	local query = reason and {reason = reason}
	if days then
		query = query or {}
		query['delete-message-days'] = days
	end
	id = Resolver.userId(id)
	local data, err = self.client._api:createGuildBan(self._id, id, query)
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m unbanUser
@t http
@p id User-ID-Resolvable
@op reason string
@r boolean
@d Unbans a user/member from the guild with an optional reason.
]=]
function Guild:unbanUser(id, reason)
	id = Resolver.userId(id)
	local query = reason and {reason = reason}
	local data, err = self.client._api:removeGuildBan(self._id, id, query)
	if data then
		return true
	else
		return false, err
	end
end

--[=[@p shardId number The ID of the shard on which this guild is served. If only one shard is in
operation, then this will always be 0.]=]
function get.shardId(self)
	return floor(self._id / 2^22) % self.client._total_shard_count
end

--[=[@p name string The guild's name. This should be between 2 and 100 characters in length.]=]
function get.name(self)
	return self._name
end

--[=[@p icon string/nil The hash for the guild's custom icon, if one is set.]=]
function get.icon(self)
	return self._icon
end

--[=[@p iconURL string/nil The URL that can be used to view the guild's icon, if one is set.]=]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._id, icon)
end

--[=[@p splash string/nil The hash for the guild's custom splash image, if one is set. Only partnered
guilds may have this.]=]
function get.splash(self)
	return self._splash
end

--[=[@p splashURL string/nil The URL that can be used to view the guild's custom splash image, if one is set.
Only partnered guilds may have this.]=]
function get.splashURL(self)
	local splash = self._splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._id, splash)
end

--[=[@p banner string/nil The hash for the guild's custom banner, if one is set.]=]
function get.banner(self)
	return self._banner
end

--[=[@p bannerURL string/nil The URL that can be used to view the guild's banner, if one is set.]=]
function get.bannerURL(self)
	local banner = self._banner
	return banner and format('https://cdn.discordapp.com/banners/%s/%s.png', self._id, banner)
end

--[=[@p large boolean Whether the guild has an arbitrarily large amount of members. Guilds that are
"large" will not initialize with all members cached.]=]
function get.large(self)
	return self._large
end

--[=[@p lazy boolean Whether the guild follows rules for the lazy-loading of client data.]=]
function get.lazy(self)
	return self._lazy
end

--[=[@p region string The voice region that is used for all voice connections in the guild.]=]
function get.region(self)
	return self._region
end

--[=[@p vanityCode string/nil The guild's vanity invite URL code, if one exists.]=]
function get.vanityCode(self)
	return self._vanity_url_code
end

--[=[@p description string/nil The guild's custom description, if one exists.]=]
function get.description(self)
	return self._description
end

--[=[@p maxMembers number/nil The guild's maximum member count, if available.]=]
function get.maxMembers(self)
	return self._max_members
end

--[=[@p maxPresences number/nil The guild's maximum presence count, if available.]=]
function get.maxPresences(self)
	return self._max_presences
end

--[=[@p mfaLevel number The guild's multi-factor (or two-factor) verification level setting. A value of
0 indicates that MFA is not required; a value of 1 indicates that MFA is
required for administrative actions.]=]
function get.mfaLevel(self)
	return self._mfa_level
end

--[=[@p joinedAt string The date and time at which the current user joined the guild, represented as
an ISO 8601 string plus microseconds when available.]=]
function get.joinedAt(self)
	return self._joined_at
end

--[=[@p afkTimeout number The guild's voice AFK timeout in seconds.]=]
function get.afkTimeout(self)
	return self._afk_timeout
end

--[=[@p unavailable boolean Whether the guild is unavailable. If the guild is unavailable, then no property
is guaranteed to exist except for this one and the guild's ID.]=]
function get.unavailable(self)
	return self._unavailable or false
end

--[=[@p totalMemberCount number The total number of members that belong to this guild. This should always be
greater than or equal to the total number of cached members.]=]
function get.totalMemberCount(self)
	return self._member_count
end

--[=[@p verificationLevel number The guild's verification level setting. See the `verificationLevel`
enumeration for a human-readable representation.]=]
function get.verificationLevel(self)
	return self._verification_level
end

--[=[@p notificationSetting number The guild's default notification setting. See the `notficationSetting`
enumeration for a human-readable representation.]=]
function get.notificationSetting(self)
	return self._default_message_notifications
end

--[=[@p explicitContentSetting number The guild's explicit content level setting. See the `explicitContentLevel`
enumeration for a human-readable representation.]=]
function get.explicitContentSetting(self)
	return self._explicit_content_filter
end

--[=[@p premiumTier number The guild's premier tier affected by nitro server
boosts. See the `premiumTier` enumeration for a human-readable representation]=]
function get.premiumTier(self)
	return self._premium_tier
end

--[=[@p premiumSubscriptionCount number The number of users that have upgraded
the guild with nitro server boosting.]=]
function get.premiumSubscriptionCount(self)
	return self._premium_subscription_count
end

--[=[@p features table Raw table of VIP features that are enabled for the guild.]=]
function get.features(self)
	return self._features
end

--[=[@p me Member/nil Equivalent to `Guild.members:get(Guild.client.user.id)`.]=]
function get.me(self)
	return self._members:get(self.client._user._id)
end

--[=[@p owner Member/nil Equivalent to `Guild.members:get(Guild.ownerId)`.]=]
function get.owner(self)
	return self._members:get(self._owner_id)
end

--[=[@p ownerId string The Snowflake ID of the guild member that owns the guild.]=]
function get.ownerId(self)
	return self._owner_id
end

--[=[@p afkChannelId string/nil The Snowflake ID of the channel that is used for AFK members, if one is set.]=]
function get.afkChannelId(self)
	return self._afk_channel_id
end

--[=[@p afkChannel GuildVoiceChannel/nil Equivalent to `Guild.voiceChannels:get(Guild.afkChannelId)`.]=]
function get.afkChannel(self)
	return self._voice_channels:get(self._afk_channel_id)
end

--[=[@p systemChannelId string/nil The channel id where Discord's join messages will be displayed.]=]
function get.systemChannelId(self)
	return self._system_channel_id
end

--[=[@p systemChannel GuildTextChannel/nil The channel where Discord's join messages will be displayed.]=]
function get.systemChannel(self)
	return self._text_channels:get(self._system_channel_id)
end

--[=[@p defaultRole Role Equivalent to `Guild.roles:get(Guild.id)`.]=]
function get.defaultRole(self)
	return self._roles:get(self._id)
end

--[=[@p connection VoiceConnection/nil The VoiceConnection for this guild if one exists.]=]
function get.connection(self)
	return self._connection
end

--[=[@p roles Cache An iterable cache of all roles that exist in this guild. This includes the
default everyone role.]=]
function get.roles(self)
	return self._roles
end

--[=[@p emojis Cache An iterable cache of all emojis that exist in this guild. Note that standard
unicode emojis are not found here; only custom emojis.]=]
function get.emojis(self)
	return self._emojis
end

--[=[@p members Cache An iterable cache of all members that exist in this guild and have been
already loaded. If the `cacheAllMembers` client option (and the `syncGuilds`
option for user-accounts) is enabled on start-up, then all members will be
cached. Otherwise, offline members may not be cached. To access a member that
may exist, but is not cached, use `Guild:getMember`.]=]
function get.members(self)
	return self._members
end

--[=[@p textChannels Cache An iterable cache of all text channels that exist in this guild.]=]
function get.textChannels(self)
	return self._text_channels
end

--[=[@p voiceChannels Cache An iterable cache of all voice channels that exist in this guild.]=]
function get.voiceChannels(self)
	return self._voice_channels
end

--[=[@p categories Cache An iterable cache of all channel categories that exist in this guild.]=]
function get.categories(self)
	return self._categories
end

return Guild
