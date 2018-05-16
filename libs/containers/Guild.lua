--[=[@c Guild x Snowflake ...]=]

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

function Guild:_makeAvailable(data)

	self._roles:_load(data.roles)
	self._emojis:_load(data.emojis)
	self._features = data.features

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
		if t == channelType.text then
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
@r boolean
@d ...
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
@r boolean
@d ...
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
@p id User-ID-Resolvable
@r Member
@d ...
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
@m getMember
@p id User-ID-Resolvable
@r Member
@d ...
]=]
function Guild:getRole(id)
	id = Resolver.roleId(id)
	return self._roles:get(id)
end

--[=[
@m getEmoji
@p id Emoji-ID-Resolvable
@r Emoji
@d ...
]=]
function Guild:getEmoji(id)
	id = Resolver.emojiId(id)
	return self._emojis:get(id)
end

--[=[
@m getChannel
@p id Channel-ID-Resolvable
@r GuildChannel
@d ...
]=]
function Guild:getChannel(id)
	id = Resolver.channelId(id)
	return self._text_channels:get(id) or self._voice_channels:get(id) or self._categories:get(id)
end

--[=[
@m createTextChannel
@p name string
@r GuildTextChannel
@d ...
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
@p name string
@r GuildVoiceChannel
@d ...
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
@p name string
@r GuildCategoryChannel
@d ...
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
@p name string
@r Role
@d ...
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
@p name string
@p image Base64-Resolvable
@r Emoji
@d ...
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
@p name string
@r boolean
@d ...
]=]
function Guild:setName(name)
	return self:_modify({name = name or json.null})
end

--[=[
@m setRegion
@p region string
@r boolean
@d ...
]=]
function Guild:setRegion(region)
	return self:_modify({region = region or json.null})
end

--[=[
@m setVerificationLevel
@p verification_level number
@r boolean
@d ...
]=]
function Guild:setVerificationLevel(verification_level)
	return self:_modify({verification_level = verification_level or json.null})
end

--[=[
@m setNotificationSetting
@p default_message_notifications number
@r boolean
@d ...
]=]
function Guild:setNotificationSetting(default_message_notifications)
	return self:_modify({default_message_notifications = default_message_notifications or json.null})
end

--[=[
@m setExplicitContentSetting
@p explicit_content_filter number
@r boolean
@d ...
]=]
function Guild:setExplicitContentSetting(explicit_content_filter)
	return self:_modify({explicit_content_filter = explicit_content_filter or json.null})
end

--[=[
@m setAFKTimeout
@p afk_timeout number
@r number
@d ...
]=]
function Guild:setAFKTimeout(afk_timeout)
	return self:_modify({afk_timeout = afk_timeout or json.null})
end

--[=[
@m setAFKChannel
@p id Channel-ID-Resolvable
@r boolean
@d ...
]=]
function Guild:setAFKChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({afk_channel_id = id or json.null})
end

--[=[
@m setSystemChannel
@p id Channel-Id-Resolvable
@r boolean
@d ...
]=]
function Guild:setSystemChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({system_channel_id = id or json.null})
end

--[=[
@m setOwner
@p id User-ID-Resolvable
@r boolean
@d ...
]=]
function Guild:setOwner(id)
	id = id and Resolver.userId(id)
	return self:_modify({owner_id = id or json.null})
end

--[=[
@m setIcon
@p icon Base64-Resolvable
@r boolean
@d ...
]=]
function Guild:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[=[
@m setSplash
@p splash Base64-Resolvable
@r boolean
@d ...
]=]
function Guild:setSplash(splash)
	splash = splash and Resolver.base64(splash)
	return self:_modify({splash = splash or json.null})
end

--[=[
@m getPruneCount
@p days number
@r number
@d ...
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
@p days number
@r number
@d ...
]=]
function Guild:pruneMembers(days)
	local data, err = self.client._api:beginGuildPrune(self._id, nil, days and {days = days} or nil)
	if data then
		return data.pruned
	else
		return nil, err
	end
end

--[=[
@m getBans
@r Cache
@d ...
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
@m getInvites
@r Cache
@d ...
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
@p query table
@r Cache
@d ...
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
@r Cache
@d ...
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
@r table
@d ...
]=]
function Guild:listVoiceRegions()
	return self.client._api:getGuildVoiceRegions(self._id)
end

--[=[
@m leave
@r boolean
@d ...
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
@r boolean
@d ...
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
@p id User-ID-Resolvable
@p reason string
@r boolean
@d ...
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
@p id User-ID-Resolvable
@p reason string
@p days number
@r boolean
@d ...
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
@p id User-ID-Resolvable
@p reason string
@r boolean
@d ...
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

--[=[@p shardId number ...]=]
function get.shardId(self)
	return floor(self._id / 2^22) % self.client._total_shard_count
end

--[=[@p name string ...]=]
function get.name(self)
	return self._name
end

--[=[@p icon string|nil ...]=]
function get.icon(self)
	return self._icon
end

--[=[@p iconURL string|nil ...]=]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._id, icon)
end

--[=[@p splash string|nil ...]=]
function get.splash(self)
	return self._splash
end

--[=[@p splashURL string|nil ...]=]
function get.splashURL(self)
	local splash = self._splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._id, splash)
end

--[=[@p large boolean ...]=]
function get.large(self)
	return self._large
end

--[=[@p region string ...]=]
function get.region(self)
	return self._region
end

--[=[@p mfaLevel number ...]=]
function get.mfaLevel(self)
	return self._mfa_level
end

--[=[@p joinedAt string ...]=]
function get.joinedAt(self)
	return self._joined_at
end

--[=[@p afkTimeout number ...]=]
function get.afkTimeout(self)
	return self._afk_timeout
end

--[=[@p unavailable boolean ...]=]
function get.unavailable(self)
	return self._unavailable or false
end

--[=[@p totalMemberCount number ...]=]
function get.totalMemberCount(self)
	return self._member_count
end

--[=[@p verificationLevel number ...]=]
function get.verificationLevel(self)
	return self._verification_level
end

--[=[@p notificationSetting number ...]=]
function get.notificationSetting(self)
	return self._default_message_notifications
end

--[=[@p explicitContentSetting number ...]=]
function get.explicitContentSetting(self)
	return self._explicit_content_filter
end

--[=[@p features table ...]=]
function get.features(self)
	return self._features
end

--[=[@p me Member|nil ...]=]
function get.me(self)
	return self._members:get(self.client._user._id)
end

--[=[@p owner Member|nil ...]=]
function get.owner(self)
	return self._members:get(self._owner_id)
end

--[=[@p ownerId string ...]=]
function get.ownerId(self)
	return self._owner_id
end

--[=[@p afkChannelId string|nil ...]=]
function get.afkChannelId(self)
	return self._afk_channel_id
end

--[=[@p afkChannel GuildVoiceChannel|nil ...]=]
function get.afkChannel(self)
	return self._voice_channels:get(self._afk_channel_id)
end

--[=[@p systemChannelId string|nil ...]=]
function get.systemChannelId(self)
	return self._system_channel_id
end

--[=[@p systemChannel GuildTextChannel|nil ...]=]
function get.systemChannel(self)
	return self._text_channels:get(self._system_channel_id)
end

--[=[@p defaultRole Role ...]=]
function get.defaultRole(self)
	return self._roles:get(self._id)
end

--[=[@p roles Cache ...]=]
function get.roles(self)
	return self._roles
end

--[=[@p emojis Cache ...]=]
function get.emojis(self)
	return self._emojis
end

--[=[@p members Cache ...]=]
function get.members(self)
	return self._members
end

--[=[@p textChannels Cache ...]=]
function get.textChannels(self)
	return self._text_channels
end

--[=[@p voiceChannels Cache ...]=]
function get.voiceChannels(self)
	return self._voice_channels
end

--[=[@p categories Cache ...]=]
function get.categories(self)
	return self._categories
end

return Guild
