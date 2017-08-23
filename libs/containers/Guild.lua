local Cache = require('iterables/Cache')
local Role = require('containers/Role')
local Emoji = require('containers/Emoji')
local Invite = require('containers/Invite')
local Webhook = require('containers/Webhook')
local Ban = require('containers/Ban')
local Member = require('containers/Member')
local Resolver = require('client/Resolver')
local GuildTextChannel = require('containers/GuildTextChannel')
local GuildVoiceChannel = require('containers/GuildVoiceChannel')
local Snowflake = require('containers/abstract/Snowflake')

local json = require('json')
local enums = require('enums')

local channelType = enums.channelType
local floor = math.floor
local format = string.format

local Guild, get = require('class')('Guild', Snowflake)

--[[
@class Guild x Snowflake

Represents a Discord guild (or server). Guilds are a collection of members,
channels, and roles that represents one community.
]]
function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._roles = Cache({}, Role, self)
	self._emojis = Cache({}, Emoji, self)
	self._members = Cache({}, Member, self)
	self._text_channels = Cache({}, GuildTextChannel, self)
	self._voice_channels = Cache({}, GuildVoiceChannel, self)
	if not data.unavailable then
		return self:_makeAvailable(data)
	end
end

function Guild:_makeAvailable(data)

	self._roles:_load(data.roles)
	self._emojis:_load(data.emojis)

	local voice_states = data.voice_states
	for i, state in ipairs(voice_states) do
		voice_states[state.user_id] = state
		voice_states[i] = nil
	end
	self._voice_states = voice_states

	local text_channels = self._text_channels
	local voice_channels = self._voice_channels
	for _, channel in ipairs(data.channels) do
		if channel.type == channelType.text then
			text_channels:_insert(channel)
		elseif channel.type == channelType.voice then
			voice_channels:_insert(channel)
		end
	end

	self._features = data.features

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
	if self._large and self.client._options.fetchMembers then
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

--[[
@method requestMembers
@tags ws
@ret boolean

Asynchronously loads all members for this guild. You do not need to call this
if the `fetchMembers` client option (and the `syncGuilds` option for
user-accounts) is enabled on start-up.
]]
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

--[[
@method sync
@tags ws
@ret boolean

Asynchronously loads certain data and enables the receiving of certain events
for this guild. You do not need to call this if the `syncGuilds` client option
is enabled on start-up.

Note: This is only for user accounts. Bot accounts never need to sync guilds!
]]
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

--[[
@method getMember
@tags http
@param id: User ID Resolveable
@ret Member

Gets a member object by ID. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made.
]]
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

--[[
@method getRole
@param id: Role ID Resolveable
@ret Role

Gets a role object by ID.
]]
function Guild:getRole(id)
	id = Resolver.roleId(id)
	return self._roles:get(id)
end

--[[
@method getChannel
@param id: Channel ID Resolveable
@ret GuildChannel

Gets a text or voice channel object by ID.
]]
function Guild:getChannel(id)
	id = Resolver.channelId(id)
	return self._text_channels:get(id) or self._voice_channels:get(id)
end

--[[
@method createTextChannel
@tags http
@param name: string
@ret GuildTextChannel

Creates a new text channel in this guild. The name must be between 2 and 100
characters in length.
]]
function Guild:createTextChannel(name)
	local data, err = self.client._api:createGuildChannel(self._id, {name = name, type = channelType.text})
	if data then
		return self._text_channels:_insert(data)
	else
		return nil, err
	end
end

--[[
@method createVoicehannel
@tags http
@param name: string
@ret GuildVoicehannel

Creates a new voice channel in this guild. The name must be between 2 and 100
characters in length.
]]
function Guild:createVoiceChannel(name)
	local data, err = self.client._api:createGuildChannel(self._id, {name = name, type = channelType.voice})
	if data then
		return self._voice_channels:_insert(data)
	else
		return nil, err
	end
end

--[[
@method createRole
@tags http
@param name: string
@ret Role

Creates a new role in this guild. The name must be between 1 and 100 characters
in length.
]]
function Guild:createRole(name)
	local data, err = self.client._api:createGuildRole(self._id, {name = name})
	if data then
		return self._roles:_insert(data)
	else
		return nil, err
	end
end

--[[
@method setName
@tags http
@param name: string
@ret boolean

Sets the guilds name. This must be between 2 and 100 characters in length.
]]
function Guild:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setRegion
@tags http
@param region: string
@ret boolean

Sets the guild's voice region (eg: `us-east`). See `listVoiceRegions` for a list
of acceptable regions.
]]
function Guild:setRegion(region)
	return self:_modify({region = region or json.null})
end

--[[
@method setVerificationLevel
@tags http
@param verificationLevel: number
@ret boolean

Sets the guild's verification leve settingl. See the `verificationLevel`
enumeration for acceptable values.
]]
function Guild:setVerificationLevel(verification_level)
	return self:_modify({verification_level = verification_level or json.null})
end

--[[
@method setNotificationSetting
@tags http
@param notificationSetting: number
@ret boolean

Sets the guild's default notification setting. See the `notficationSetting`
enumeration for acceptable values.
]]
function Guild:setNotificationSetting(default_message_notifications)
	return self:_modify({default_message_notifications = default_message_notifications or json.null})
end

--[[
@method setExplicitContentSetting
@tags http
@param explicitContentSetting: number
@ret boolean

Sets the guild's explicit content level setting. See the `explicitContentLevel`

]]
function Guild:setExplicitContentSetting(explicit_content_filter)
	return self:_modify({explicit_content_filter = explicit_content_filter or json.null})
end

--[[
@method setAFKTimeout
@tags http
@param afkTimeout: number
@ret boolean

Sets the guild's AFK timeout in seconds.
]]
function Guild:setAFKTimeout(afk_timeout)
	return self:_modify({afk_timeout = afk_timeout or json.null})
end

--[[
@method setAFKChannel
@tags http
@param id: Channel ID Resolveable
@ret boolean

Sets the guild's AFK channel.
]]
function Guild:setAFKChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({afk_channel_id = id or json.null})
end

--[[
@method setOwner
@tags http
@param id: User ID Resolveable
@ret boolean

Transfers ownership of the guild to another user. Only the current guild user
can do this.
]]
function Guild:setOwner(id)
	id = id and Resolver.userId(id)
	return self:_modify({owner_id = id or json.null})
end

--[[
@method setIcon
@tags http
@param icon: Base64 Resolveable
@ret boolean

Sets the guild's icon. To remove the icon, pass `nil`.
]]
function Guild:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[[
@method setSplash
@tags http
@param splash: Base64 Resolveable
@ret boolean

Sets the guild's splash. To remove the splash, pass `nil`.
]]
function Guild:setSplash(splash)
	splash = splash and Resolver.base64(splash)
	return self:_modify({splash = splash or json.null})
end

--[[
@method getPruneCount
@tags http
@param days: number
@ret number

Returns the number of members that would be pruned from the guild if a prune
were to be executed.
]]
function Guild:getPruneCount(days)
	local data, err = self.client._api:getGuildPruneCount(self._id, days and {days = days} or nil)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

--[[
@method pruneMembers
@tags http
@param days: number
@ret number

Prunes (removes) inactive, roleless members from the guild.
]]
function Guild:pruneMembers(days)
	local data, err = self.client._api:beginGuildPrune(self._id, nil, days and {days = days} or nil)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

--[[
@method getBans
@tags http
@ret Cache

Returns a newly constructed cache of all ban objects for the guild. The
cache is not automatically updated via gateway events, but the internally
referenced user objects may be updated. You must call this method again to
guarantee that the objects are update to date.
]]
function Guild:getBans()
	local data, err = self.client._api:getGuildBans(self._id)
	if data then
		return Cache(data, Ban, self)
	else
		return nil, err
	end
end

--[[
@method getInvites
@tags http
@ret Cache

Returns a newly constructed cache of all invite objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]]
function Guild:getInvites()
	local data, err = self.client._api:getGuildInvites(self._id)
	if data then
		return Cache(data, Invite, self.client)
	else
		return nil, err
	end
end

--[[
@method getWebhooks
@tags http
@ret Cache

Returns a newly constructed cache of all webhook objects for the guild. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]]
function Guild:getWebhooks()
	local data, err = self.client._api:getGuildWebhooks(self._id)
	if data then
		return Cache(data, Webhook, self.client)
	else
		return nil, err
	end
end

--[[
@method listVoiceRegions
@tags http
@ret table

Returns a raw data table that contains a list of available voice regions for
this guild, as provided by Discord, with no additional parsing.
]]
function Guild:listVoiceRegions()
	return self.client._api:getGuildVoiceRegions()
end

--[[
@method leave
@tags http
@ret boolean

Removes the current from the guild.
]]
function Guild:leave()
	local data, err = self.client._api:leaveGuild(self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method delete
@tags http
@ret boolean

Permanently deletes the guild. This cannot be undone!
]]
function Guild:delete()
	local data, err = self.client._api:deleteGuild(self._id)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method kiskUser
@tags http
@param id: User ID Resolveable
@param [reason]: string
@ret boolean

Kicks a user/member from the guild with an optional reason.
]]
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

--[[
@method banUser
@tags http
@param id: User ID Resolveable
@param [reason]: string
@param [days]: number
@ret boolean

Bans a user/member from the guild with an optional reason. The `days` parameter
is the number of days to consider when purging messages, up to 7.
]]
function Guild:banUser(user, reason, days)
	local query = reason and {reason = reason}
	if days then
		query = query or {}
		query['delete-message-days'] = days
	end
	user = Resolver.userId(user)
	local data, err = self.client._api:createGuildBan(self._id, user, query)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method unbanUser
@tags http
@param id: User ID Resolveable
@param [reason]: string
@ret boolean

Unbans a user/member from the guild with an optional reason.
]]
function Guild:unbanUser(user, reason)
	user = Resolver.userId(user)
	local query = reason and {reason = reason}
	local data, err = self.client._api:removeGuildBan(self._id, user, query)
	if data then
		return true
	else
		return false, err
	end
end

--[[
@property shardId: number

The ID of the shard on which this guild is served. If only one shard is in
operation, then this will always be 0.
]]
function get.shardId(self)
	return floor(self._id / 2^22) % self.client._shard_count
end

--[[
@property name: string

The guild's name. This should be between 2 and 100 characters in length.
]]
function get.name(self)
	return self._name
end

--[[
@property icon: string|nil

The hash for the guild's custom icon, if one is set.
]]
function get.icon(self)
	return self._icon
end

--[[
@property iconURL: string|nil

The URL that can be used to view the guild's icon, if one is set.
]]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._id, icon)
end

--[[
@property splash: string|nil

The hash for the guild's custom splash image, if one is set. Only partnered
guilds may have this.
]]
function get.splash(self)
	return self._splash
end

--[[
@property splashURL: string|nil

The URL that can be used to view the guild's custom splash image, if one is set.
Only partnered guilds may have this.
]]
function get.splashURL(self)
	local splash = self._splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._id, splash)
end

--[[
@property large: boolean

Whether the guild has an arbitrarily large amount of members. Guilds that are
"large" will not initialize with all members.
]]
function get.large(self)
	return self._large
end

--[[
@property region: string

The voice region that is used for all voice connections in the guild.
]]
function get.region(self)
	return self._region
end

--[[
@property mfaLevel: number

The guild's multi-factor (or two-factor) verification level setting. See the
`verificationLevel` enumeration for a human-readable representation.
]]
function get.mfaLevel(self)
	return self._mfa_level
end

--[[
@property joinedAt: string

The date and time at which the current user joined the guild, represented as
an ISO 8601 string plus microseconds when available.
]]
function get.joinedAt(self)
	return self._joined_at
end

--[[
@property afkTimeout: number

The guild's voice AFK timeout in seconds.
]]
function get.afkTimeout(self)
	return self._afk_timeout
end

--[[
@property unavailable: boolean

Whether the guild is unavailable. If the guild is unavailable, then no property
is guaranteed to exist except for this one and the guild's ID.
]]
function get.unavailable(self)
	return self._unavailable or false
end

--[[
@property totalMemberCount: number

The total number of members that belong to this guild. This should always be
greater than or equal to the total number of cached members.
]]
function get.totalMemberCount(self)
	return self._member_count
end

--[[
@property verificationLevel: number

The guild's verification level setting. See the `verificationLevel`
enumeration for a human-readable representation.
]]
function get.verificationLevel(self)
	return self._verification_level
end

--[[
@property notificationSetting: number

The guild's default notification setting. See the `notficationSetting`
enumeration for a human-readable representation.
]]
function get.notificationSetting(self)
	return self._default_message_notifications
end

--[[
@property explicitContentSetting: number

The guild's explicit content level setting. See the `explicitContentLevel`
enumeration for a human-readable representation.
]]
function get.explicitContentSetting(self)
	return self._explicit_content_filter
end

--[[
#property features: table

Raw table of VIP features that are enabled for the guild.
]]
function get.features(self)
	return self._features
end

--[[
@property me: Member|nil

Equivalent to `$.members:get($.client.user.id)`.
]]
function get.me(self)
	return self._members:get(self.client._user._id)
end

--[[
@property owner: Member|nil

Equivalent to `$.members:get($.ownerId)`.
]]
function get.owner(self)
	return self._members:get(self._owner_id)
end

--[[
@property ownerId: string

The Snowflake ID of the guild member that owns the guild.
]]
function get.ownerId(self)
	return self._owner_id
end

--[[
@property afkChannelId: string|nil

The Snowflake ID of the channel that is used for AFK members, if one is set.
]]
function get.afkChannelId(self)
	return self._afk_channel_id
end

--[[
@property afkChannel: GuildVoiceChannel|nil

Equivalent to `$.voiceChannels:get($.afkChannelId)`.
]]
function get.afkChannel(self)
	return self._voice_channels:get(self._afk_channel_id)
end

--[[
@property defaultRole: Role

Equivalent to `$.roles:get($.id)`.
]]
function get.defaultRole(self)
	return self._roles:get(self._id)
end

--[[
@property roles: Cache

An iterable cache of all roles that exist in this guild. This includes the
default everyone role.
]]
function get.roles(self)
	return self._roles
end

--[[
@property emojis: Cache

An iterable cache of all emojis that exist in this guild. Note that standard
unicode emojis are not found here; only custom emojis.
]]
function get.emojis(self)
	return self._emojis
end

--[[
@property members: Cache

An iterable cache of all members that exist in this guild and have been
already loaded. If the `fetchMembers` client option (and the `syncGuilds` option
for user-accounts) is enabled on start-up, then all members will be cached.
Otherwise, all members may not be cached. To access a member that may exist, but
is not cached, use `Guild:getMember`.
]]
function get.members(self)
	return self._members
end

--[[
@property textChannels: Cache

An iterable cache of all text channels that exist in this guild.
]]
function get.textChannels(self)
	return self._text_channels
end

--[[
@property voiceChannels: Cache

An iterable cache of all voice channels that exist in this guild.
]]
function get.voiceChannels(self)
	return self._voice_channels
end

return Guild
