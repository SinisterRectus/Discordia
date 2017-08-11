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

	self._features = data.features -- raw table of strings

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
@ret boolean
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
@ret boolean
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
@param id: User ID Resolveable
@ret Member
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
]]
function Guild:getRole(id)
	id = Resolver.roleId(id)
	return self._roles:get(id)
end

--[[
@method getChannel
@param id: Channel ID Resolveable
@ret GuildChannel
]]
function Guild:getChannel(id)
	id = Resolver.channelId(id)
	return self._text_channels:get(id) or self._voice_channels:get(id)
end

--[[
@method createTextChannel
@param name: string
@ret GuildTextChannel
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
@param name: string
@ret GuildVoicehannel
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
@param name: string
@ret Role
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
@param name: string
@ret boolean
]]
function Guild:setName(name)
	return self:_modify({name = name or json.null})
end

--[[
@method setRegion
@param region: string
@ret boolean
]]
function Guild:setRegion(region)
	return self:_modify({region = region or json.null})
end

--[[
@method setVerificationLevel
@param verificationLevel: number
@ret boolean
]]
function Guild:setVerificationLevel(verification_level)
	return self:_modify({verification_level = verification_level or json.null})
end

--[[
@method setNotificationSetting
@param notificationSetting: number
@ret boolean
]]
function Guild:setNotificationSetting(default_message_notifications)
	return self:_modify({default_message_notifications = default_message_notifications or json.null})
end

--[[
@method setExplicitContentSetting
@param explicitContentSetting: number
@ret boolean
]]
function Guild:setExplicitContentSetting(explicit_content_filter)
	return self:_modify({explicit_content_filter = explicit_content_filter or json.null})
end

--[[
@method setAFKTimeout
@param afkTimeout: number
@ret boolean
]]
function Guild:setAFKTimeout(afk_timeout)
	return self:_modify({afk_timeout = afk_timeout or json.null})
end

--[[
@method setAFKChannel
@param id: Channel ID Resolveable
@ret boolean
]]
function Guild:setAFKChannel(id)
	id = id and Resolver.channelId(id)
	return self:_modify({afk_channel_id = id or json.null})
end

--[[
@method setOwner
@param id: User ID Resolveable
@ret boolean
]]
function Guild:setOwner(id)
	id = id and Resolver.userId(id)
	return self:_modify({owner_id = id or json.null})
end

--[[
@method setIcon
@param icon: Base64 Resolveable
@ret boolean
]]
function Guild:setIcon(icon)
	icon = icon and Resolver.base64(icon)
	return self:_modify({icon = icon or json.null})
end

--[[
@method setSplash
@param splash: Base64 Resolveable
@ret boolean
]]
function Guild:setSplash(splash)
	splash = splash and Resolver.base64(splash)
	return self:_modify({splash = splash or json.null})
end

--[[
@method getPruneCount
@param days: number
@ret number
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
@param days: number
@ret number
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
@ret Cache
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
@ret Cache
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
@ret Cache
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
@ret table
]]
function Guild:listVoiceRegions()
	return self.client._api:getGuildVoiceRegions()
end

--[[
@method leave
@ret boolean
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
@ret boolean
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
@param id: User ID Resolveable
@param reason: string
@ret boolean
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
@param id: User ID Resolveable
@param reason: string
@param days: number
@ret boolean
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
@param id: User ID Resolveable
@param reason: string
@ret boolean
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
]]
function get.shardId(self)
	return floor(self._id / 2^22) % self.client._shard_count
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property icon: string|nil
]]
function get.icon(self)
	return self._icon
end

--[[
@property iconURL: string|nil
]]
function get.iconURL(self)
	local icon = self._icon
	return icon and format('https://cdn.discordapp.com/icons/%s/%s.png', self._id, icon) or nil
end

--[[
@property splash: string|nil
]]
function get.splash(self)
	return self._splash
end

--[[
@property splashURL: string|nil
]]
function get.splashURL(self)
	local splash = self._splash
	return splash and format('https://cdn.discordapp.com/splashs/%s/%s.png', self._id, splash) or nil
end

--[[
@property large: boolean
]]
function get.large(self)
	return self._large
end

--[[
@property region: string
]]
function get.region(self)
	return self._region
end

--[[
@property mfaLevel: number
]]
function get.mfaLevel(self)
	return self._mfa_level
end

--[[
@property joinedAt: string
]]
function get.joinedAt(self)
	return self._joined_at
end

--[[
@property afkTimeout: number
]]
function get.afkTimeout(self)
	return self._afk_timeout
end

--[[
@property unavailable: boolean
]]
function get.unavailable(self)
	return self._unavailable or false
end

--[[
@property totalMemberCount: number
]]
function get.totalMemberCount(self)
	return self._member_count
end

--[[
@property verificationLevel: number
]]
function get.verificationLevel(self)
	return self._verification_level
end

--[[
@property notificationSetting: number
]]
function get.notificationSetting(self)
	return self._default_message_notifications
end

--[[
@property explicitContentSetting: number
]]
function get.explicitContentSetting(self)
	return self._explicit_content_filter
end

--[[
@property me: Member|nil
]]
function get.me(self)
	return self._members:get(self.client._user._id)
end

--[[
@property owner: Member|nil
]]
function get.owner(self)
	return self._members:get(self._owner_id)
end

--[[
@property ownerId: string
]]
function get.ownerId(self)
	return self._owner_id
end

--[[
@property afkChannelId: string|nil
]]
function get.afkChannelId(self)
	return self._afk_channel_id
end

--[[
@property afkChannel: GuildVoiceChannel|nil
]]
function get.afkChannel(self)
	return self._voice_channels:get(self._afk_channel_id)
end

--[[
@property defaultRole: Role
]]
function get.defaultRole(self)
	return self._roles:get(self._id)
end

--[[
@property roles: Cache
]]
function get.roles(self)
	return self._roles
end

--[[
@property emojis: Cache
]]
function get.emojis(self)
	return self._emojis
end

--[[
@property members: Cache
]]
function get.members(self)
	return self._members
end

--[[
@property textChannels: Cache
]]
function get.textChannels(self)
	return self._text_channels
end

--[[
@property voiceChannels: Cache
]]
function get.voiceChannels(self)
	return self._voice_channels
end

return Guild
