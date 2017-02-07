local Snowflake = require('../Snowflake')
local Role = require('./Role')
local Emoji = require('./Emoji')
local Member = require('./Member')
local GuildTextChannel = require('./channels/GuildTextChannel')
local GuildVoiceChannel = require('./channels/GuildVoiceChannel')
local Invite = require('../Invite')
local Cache = require('../../utils/Cache')

local hash = table.hash
local format = string.format
local floor, clamp = math.floor, math.clamp
local wrap, yield = coroutine.wrap, coroutine.yield

local Guild, property, method, cache = class('Guild', Snowflake)
Guild.__description = "Represents a Discord guild (also known as a server)."

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._roles = Cache({}, Role, 'id', self)
	self._emojis = Cache({}, Emoji, 'id', self)
	self._members = Cache({}, Member, 'id', self)
	self._text_channels = Cache({}, GuildTextChannel, 'id', self)
	self._voice_channels = Cache({}, GuildVoiceChannel, 'id', self)
	if data.unavailable then
		self._unavailable = true
	else
		self:_makeAvailable(data)
	end
end

function Guild:__tostring()
	return format('%s: %s', self.__name, self._name)
end

function Guild:_makeAvailable(data)

	self:_update(data)

	self._roles:merge(data.roles)
	self._emojis:merge(data.emojis)
	self._members:merge(data.members)

	hash(data.voice_states, 'user_id')
	self._voice_states = data.voice_states

	if data.presences then
		self:_loadMemberPresences(data.presences)
	end

	if data.channels then
		for _, channel_data in ipairs(data.channels) do
			local type = channel_data.type
			if type == 'text' then
				self._text_channels:new(channel_data)
			elseif type == 'voice' then
				self._voice_channels:new(channel_data)
			end
		end
	end

	if self._large and self._parent._options.fetchMembers then
		self:_requestMembers()
	end

	self._vip = next(data.features) and true or false

	-- TODO: parse features

end

function Guild:_requestMembers()
	local socket = self._parent._sockets[self.shardId]
	if socket._loading then
		socket._loading.chunks[self._id] = true
	end
	socket:requestGuildMembers(self._id)
end

function Guild:_loadMemberPresences(data)
	for _, presence in ipairs(data) do
		local member = self._members:get(presence.user.id)
		member:_createPresence(presence)
	end
end

function Guild:_updateMemberPresence(data)
	local member = self._members:get(data.user.id)
	if member then
		member:_updatePresence(data)
	else
		member = self._members:new(data)
		member:_createPresence(data)
	end
	return member
end

local function setName(self, name)
	local success, data = self._parent._api:modifyGuild(self._id, {name = name})
	if success then self._name = data.name end
	return success
end

local function setRegion(self, region)
	local success, data = self._parent._api:modifyGuild(self._id, {region = region})
	if success then self._region = data.region end
	return success
end

local function setIcon(self, icon)
	local success, data = self._parent._api:modifyGuild(self._id, {icon = icon})
	if success then self._icon = data.icon end
	return success
end

local function setOwner(self, member)
	local success, data = self._parent._api:modifyGuild(self._user._id, {owner_id = member._id})
	if success then self._owner_id = data.owner_id end
	return success
end

local function setAfkTimeout(self, timeout)
	local success, data = self._parent._api:modifyGuild(self._id, {afk_timeout = timeout})
	if success then self._afk_timeout = data.afk_timeout end
	return success
end

local function setAfkChannel(self, channel)
	local success, data = self._parent._api:modifyGuild(self._id, {afk_channel_id = channel and channel._id or self._id})
	if success then self._afk_channel_id = data._afk_channel_id end
	return success
end

local function getIconUrl(self)
	if not self._icon then return nil end
	return format('https://cdn.discordapp.com/icons/%s/%s.png', self._id, self._icon)
end

local function getShardId(self)
	return floor(self._id / 2^22) % self._parent._shard_count
end

local function getMe(self)
	return self._members:get(self._parent._user._id)
end

local function getOwner(self)
	return self._members:get(self._owner_id)
end

local function getAfkChannel(self)
	return self._voice_channels:get(self._afk_channel_id)
end

local function getDefaultRole(self)
	return self._roles:get(self._id)
end

local function getDefaultChannel(self)
	return self._text_channels:get(self._id)
end

local function listVoiceRegions(self)
	local success, data = self._parent._api:getGuildVoiceRegions(self._id)
	return success and data or nil
end

local function leave(self)
	return (self._parent._api:leaveGuild(self._id))
end

local function delete(self)
	return (self._parent._api:deleteGuild(self._id))
end

local function getBannedUsers(self)
	local success, data = self._parent._api:getGuildBans(self._id)
	if not success then return function() end end
	local users = self._parent._users
	local i = 1
	return function()
		local v = data[i]
		if v then
			i = i + 1
			return users:get(v.user.id) or users:new(v.user)
		end
	end
end

local function getInvites(self)
	local success, data = self._parent._api:getGuildInvites(self._id)
	local parent = self._parent
	if not success then return function() end end
	local i = 1
	return function()
		local v = data[i]
		if v then
			i = i + 1
			return Invite(v, parent)
		end
	end
end

local function banUser(self, user, days)
	local query = days and {['delete-message-days'] = clamp(days, 0, 7)} or nil
	return (self._parent._api:createGuildBan(self._id, user._id, nil, query))
end

local function unbanUser(self, user)
	return (self._parent._api:removeGuildBan(self._id, user._id))
end

local function kickUser(self, user)
	return (self._parent._api:removeGuildMember(self._id, user._id))
end

local function getPruneCount(self, days)
	local query = days and {days = clamp(days, 1, 30)} or nil
	local success, data = self._parent._api:getGuildPruneCount(self._id, query)
	return success and data.pruned or nil
end

local function pruneMembers(self, days)
	local query = days and {days = clamp(days, 1, 30)} or nil
	local success, data = self._parent._api:getGuildPruneCount(self._id, query)
	return success and data.pruned or nil
end

local function createTextChannel(self, name)
	local success, data = self._parent._api:createGuildChannel(self._id, {name = name, type = 'text'})
	return success and self._text_channels:new(data) or nil
end

local function createVoiceChannel(self, name)
	local success, data = self._parent._api:createGuildChannel(self._id, {name = name, type = 'voice'})
	return success and self._voice_channels:new(data) or nil
end

local function createRole(self)
	local success, data = self._parent._api:createGuildRole(self._id)
	return success and self._roles:new(data) or nil
end

-- channels --

local function getChannelCount(self)
	return self._text_channels._count + self._voice_channels._count
end

local function getChannels(self, key, value)
	return wrap(function()
		for channel in self._text_channels:getAll(key, value) do
			yield(channel)
		end
		for channel in self._voice_channels:getAll(key, value) do
			yield(channel)
		end
	end)
end

local function getChannel(self, key, value)
	return self._text_channels:get(key, value) or self._voice_channels:get(key, value)
end

local function findChannel(self, predicate)
	return self._text_channels:find(predicate) or self._voice_channels:find(predicate)
end

local function findChannels(self, predicate)
	return wrap(function()
		for channel in self._text_channels:findAll(predicate) do
			yield(channel)
		end
		for channel in self._voice_channels:findAll(predicate) do
			yield(channel)
		end
	end)
end

-- text channels --

local function getTextChannelCount(self)
	return self._text_channels._count
end

local function getTextChannels(self, key, value)
	return self._text_channels:getAll(key, value)
end

local function getTextChannel(self, key, value)
	return self._text_channels:get(key, value)
end

local function findTextChannel(self, predicate)
	return self._text_channels:find(predicate)
end

local function findTextChannels(self, predicate)
	return self._text_channels:findAll(predicate)
end

-- voice channels --

local function getVoiceChannelCount(self)
	return self._voice_channels._count
end

local function getVoiceChannels(self, key, value)
	return self._voice_channels:getAll(key, value)
end

local function getVoiceChannel(self, key, value)
	return self._voice_channels:get(key, value)
end

local function findVoiceChannel(self, predicate)
	return self._voice_channels:find(predicate)
end

local function findVoiceChannels(self, predicate)
	return self._voice_channels:findAll(predicate)
end

-- roles --

local function getRoleCount(self)
	return self._roles._count
end

local function getRoles(self, key, value)
	return self._roles:getAll(key, value)
end

local function getRole(self, key, value)
	return self._roles:get(key, value)
end

local function findRole(self, predicate)
	return self._roles:find(predicate)
end

local function findRoles(self, predicate)
	return self._roles:findAll(predicate)
end

-- emojis --

local function getEmojiCount(self)
	return self._emojis._count
end

local function getEmojis(self, key, value)
	return self._emojis:getAll(key, value)
end

local function getEmoji(self, key, value)
	return self._emojis:get(key, value)
end

local function findEmoji(self, predicate)
	return self._emojis:find(predicate)
end

local function findEmojis(self, predicate)
	return self._emojis:findAll(predicate)
end

-- members --

local function getMemberCount(self)
	return self._members._count
end

local function getMembers(self, key, value)
	return self._members:getAll(key, value)
end

local function getMember(self, key, value)
	local member = self._members:get(key, value)
	if member or value then return member end
	local success, data = self._parent._api:getGuildMember(self._id, key)
	return success and self._members:new(data) or nil
end

local function findMember(self, predicate)
	return self._members:find(predicate)
end

local function findMembers(self, predicate)
	return self._members:findAll(predicate)
end

-- messages --

local function getMessageCount(self)
	local n = 0
	for channel in self._text_channels:iter() do
		n = n + channel._messages._count
	end
	return n
end

local function getMessages(self, key, value)
	return wrap(function()
		for channel in self._text_channels:iter() do
			for message in channel._messages:getAll(key, value) do
				yield(message)
			end
		end
	end)
end

local function getMessage(self, key, value)
	for channel in self._text_channels:iter() do
		local message = channel._messages:get(key, value)
		if message then return message end
	end
	return nil
end

local function findMessage(self, predicate)
	for channel in self._text_channels:iter() do
		local message = channel._messages:find(predicate)
		if message then return message end
	end
	return nil
end

local function findMessages(self, predicate)
	return wrap(function()
		for channel in self._text_channels:iter() do
			for message in channel._messages:findAll(predicate) do
				yield(message)
			end
		end
	end)
end

property('vip', '_vip', nil, 'boolean', "Whether the guild is featured by Discord")
property('name', '_name', setName, 'string', "Name of the guild")
property('icon', '_icon', setIcon, 'string', "Hash representing the guild's icon")
property('iconUrl', getIconUrl, nil, 'string', "URL that points to the guild's icon")
property('large', '_large', nil, 'boolean', "Whether the guild has a lot of members")
property('splash', '_splash', nil, 'string', "Hash representing the guild's custom splash")
property('region', '_region', setRegion, 'string', "String representing the guild's voice region")
property('mfaLevel', '_mfa_level', nil, 'number', "Guild required MFA level")
property('joinedAt', '_joined_at', nil, 'string', "Date and time at which the client joined the guild")
property('afkTimeout', '_afk_timeout', setAfkTimeout, 'number', "AFK timeout in seconds")
property('unavailable', '_unavailable', nil, 'boolean', "Whether the guild data is unavailable")
property('totalMemberCount', '_member_count', nil, 'number', "How many members exist in the guild (can be different from cached memberCount)")
property('verificationLevel', '_verification_level', nil, 'number', "Guild verification level")
property('notificationsSetting', '_default_message_notifications', nil, 'number', "Default message notifications setting for members")
property('shardId', getShardId, nil, 'number', "The ID of the shard on which this guild's events will be transmitted")
property('me', getMe, nil, 'Member', "The client's member object for this guild")
property('owner', getOwner, setOwner, 'Member', "The member that owns the server")
property('afkChannel', getAfkChannel, setAfkChannel, 'GuildVoiceChannel', "Voice channel to where members are moved when they are AFK")
property('defaultRole', getDefaultRole, nil, 'Role', "The guild's '@everyone' role")
property('defaultChannel', getDefaultChannel, nil, 'GuildTextChannel', "The guild's default text channel")
property('bannedUsers', getBannedUsers, nil, 'function', "Iterator for the banned users in the guild")
property('invites', getInvites, nil, 'function', "Iterator for the guild's invites (not cached)")
property('connection', '_connection', nil, 'VoiceConnection', "The handle for this guild's voice connection, if one exists")

method('leave', leave, nil, "Leaves the guild.")
method('delete', delete, nil, "Deletes the guild.")
method('listVoiceRegions', listVoiceRegions, nil, "Returns a table of guild voice regions.")
method('banUser', banUser, 'user[, days]', "Bans a user from the guild and optionally deletes their messages from 1-7 days.")
method('unbanUser', unbanUser, 'user', "Unbans a user from the guild.")
method('kickUser', kickUser, 'user', "Kicks a user from the guild")
method('getPruneCount', getPruneCount, '[days]', "Returns how many members would be removed if 1-30 day prune were performed (default: 1 day).")
method('pruneMembers', pruneMembers, '[days]', "Removes members who have not been seen in 1-30 days (default: 1 day). Returns the number of pruned members.")
method('createTextChannel', createTextChannel, 'name', "Creates a new text channel in the guild.")
method('createVoiceChannel', createVoiceChannel, 'name', "Creates a new voice channel in the guild.")
method('createRole', createRole, nil, "Creates a new role in the guild.")

cache('Channel', getChannelCount, getChannel, getChannels, findChannel, findChannels)
cache('TextChannel', getTextChannelCount, getTextChannel, getTextChannels, findTextChannel, findTextChannels)
cache('VoiceChannel', getVoiceChannelCount, getVoiceChannel, getVoiceChannels, findVoiceChannel, findVoiceChannels)
cache('Role', getRoleCount, getRole, getRoles, findRole, findRoles)
cache('Emoji', getEmojiCount, getEmoji, getEmojis, findEmoji, findEmojis)
cache('Member', getMemberCount, getMember, getMembers, findMember, findMembers)
cache('Message', getMessageCount, getMessage, getMessages, findMessage, findMessages)

return Guild
