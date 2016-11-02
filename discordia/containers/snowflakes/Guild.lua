local Snowflake = require('../Snowflake')
local Role = require('./Role')
local User = require('./User')
local Member = require('./Member')
local GuildTextChannel = require('./channels/GuildTextChannel')
local GuildVoiceChannel = require('./channels/GuildVoiceChannel')
local Invite = require('../Invite')
local VoiceState = require('../VoiceState')
local Cache = require('../../utils/Cache')

local clamp = math.clamp
local wrap, yield = coroutine.wrap, coroutine.yield

local Guild, get, set = class('Guild', Snowflake)

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._roles = Cache({}, Role, '_id', self)
	self._members = Cache({}, Member, '_id', self)
	self._voice_states = Cache({}, VoiceState, '_session_id', self)
	self._text_channels = Cache({}, GuildTextChannel, '_id', self)
	self._voice_channels = Cache({}, GuildVoiceChannel, '_id', self)
	if data.unavailable then
		self._unavailable = true
	else
		self:_makeAvailable(data)
	end
end

get('vip', '_vip')
get('name', '_name')
get('icon', '_icon')
get('large', '_large')
get('splash', '_splash')
get('region', '_region')
get('ownerId', '_owner_id')
get('mfaLevel', '_mfa_level')
get('joinedAt', '_joined_at')
get('afkTimeout', '_afk_timeout')
get('unavailable', '_unavailable')
get('memberCount', '_member_count')
get('afkChannelId', '_afk_channel_id')
get('verificationLevel', '_verification_level')
get('defaultMessageNotifications', '_default_message_notifications')

get('me', function(self) return self._members:get(self._parent._user._id) end)
get('owner', function(self) return self._members:get(self._owner_id) end)
get('afkChannel', function(self) return self._voice_channels:get(self._afk_channel_id) end)
get('defaultRole', function(self) return self._roles:get(self._id) end)
get('defaultChannel', function(self) return self._text_channels:get(self._id) end)

function Guild:_makeAvailable(data)

	self:_update(data)

	self._roles:merge(data.roles)
	self._members:merge(data.members)
	self._voice_states:merge(data.voice_states)

	if data.presences then
		self:_loadMemberPresences(data.presences)
	end

	if data.channels then
		for _, data in ipairs(data.channels) do
			if data.type == 'text' then
				self._text_channels:new(data)
			elseif data.type == 'voice' then
				self._voice_channels:new(data)
			end
		end
	end

	if self._large and self._parent._options.fetchMembers then
		self:requestMembers()
	end

	self._vip = next(data.features) and true or false

	-- self.emojis = data.emojis -- TODO
	-- self.features = data.features -- TODO

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

function Guild:requestMembers()
	self._parent._socket:requestGuildMembers(self._id)
	if self._parent._loading then
		self._parent._loading.chunks[self._id] = true
	end
end

function Guild:listVoiceRegions()
	local success, data = self._parent._api:getGuildVoiceRegions(self._id)
	if success then return data end
end

function Guild:addMember(user) -- limit use, requires guild.join scope
	local success, data = self._parent._api:addGuildMember(self._id, user._id)
	if success then return self._members:new(data) end
end

set('name', function(self, name)
	local success, data = self._parent._api:modifyGuild(self._id, {name = name})
	if success then self._name = data.name end
	return success
end)

set('region', function(self, region)
	local success, data = self._parent._api:modifyGuild(self._id, {region = region})
	if success then self._region = data.region end
	return success
end)

set('icon', function(self, icon)
	local success, data = self._parent._api:modifyGuild(self._id, {icon = icon})
	if success then self._icon = data.icon end
	return success
end)

set('owner', function(self, user)
	local success, data = self._parent._api:modifyGuild(self._id, {owner_id = user._id})
	if success then self._owner_id = data.owner_id end
	return success
end)

set('afkTimeout', function(self, timeout)
	local success, data = self._parent._api:modifyGuild(self._id, {afk_timeout = timeout})
	if success then self._afk_timeout = data.afk_timeout end
	return success
end)

set('afkChannel', function(self, channel)
	local success, data = self._parent._api:modifyGuild(self._id, {afk_channel_id = channel and channel._id or self._id})
	if success then self._afk_channel_id = data._afk_channel_id end
	return success
end)

function Guild:leave()
	local success, data = self._parent._api:leaveGuild(self._id)
	return success
end

function Guild:delete()
	local success, data = self._parent._api:deleteGuild(self._id)
	return success
end

get('bans', function(self)
	local success, data = self._parent._api:getGuildBans(self._id)
	if not success then return function() end end
	local users = self._parent._users
	return wrap(function()
		for _, v in ipairs(data) do
			yield(users:get(v.user.id) or users:new(v.user))
		end
	end)
end)

function Guild:banUser(user, days)
	local query = days and {['delete-message-days'] = clamp(days, 0, 7)} or nil
	local success, data = self._parent._api:createGuildBan(self._id, user._id, payload, query)
	return success
end

function Guild:unbanUser(user)
	local success, data = self._parent._api:removeGuildBan(self._id, user._id)
	return success
end

function Guild:kickUser(user)
	local success, data = self._parent._api:removeGuildMember(self._id, user._id)
	return success
end

get('pruneCount', function(self, days)
	local query = days and {days = clamp(days, 1, 30)} or nil
	local success, data = self._parent._api:getGuildPruneCount(self._id, query)
	if success then return data.pruned end
end)

function Guild:pruneMembers(days)
	local query = days and {days = clamp(days, 1, 30)} or nil
	local success, data = self._parent._api:getGuildPruneCount(self._id, query)
	if success then return data.pruned end
end

function Guild:createTextChannel(name)
	local success, data = self._parent._api:createGuildChannel(self._id, {name = name, type = 'text'})
	if success then return self._text_channels:new(data) end
end

function Guild:createVoiceChannel(name)
	local success, data = self._parent._api:createGuildChannel(self._id, {name = name, type = 'voice'})
	if success then return self._voice_channels:new(data) end
end

function Guild:createRole()
	local success, data = self._parent._api:createGuildRole(self._id)
	if success then return self._roles:new(data) end
end

get('invites', function(self)
	local success, data = self._parent._api:getGuildInvites(self._id)
	local parent = self._parent
	if not success then return function() end end
	return wrap(function()
		for _, inviteData in ipairs(data) do
			yield(Invite(inviteData, parent))
		end
	end)
end)

-- channels --

get('channelCount', function(self)
	return self._text_channels._count + self._voice_channels._count
end)

get('channels', function(self, key, value)
	return wrap(function()
		for channel in self._text_channels:getAll(key, value) do
			yield(channel)
		end
		for channel in self._voice_channels:getAll(key, value) do
			yield(channel)
		end
	end)
end)

function Guild:getChannel(key, value)
	return self._text_channels:get(key, value) or self._voice_channels:get(key, value)
end

function Guild:findChannel(predicate)
	return self._text_channels:find(predicate) or self._voice_channels:find(predicate)
end

function Guild:findChannels(predicate)
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

get('textChannelCount', function(self)
	return self._text_channels._count
end)

get('textChannels', function(self, key, value)
	return self._text_channels:getAll(key, value)
end)

function Guild:getTextChannel(key, value)
	return self._text_channels:get(key, value)
end

function Guild:findTextChannel(predicate)
	return self._text_channels:find(predicate)
end

function Guild:findTextChannels(predicate)
	return self._text_channels:findAll(predicate)
end

-- voice channels --

get('voiceChannelCount', function(self)
	return self._voice_channels._count
end)

get('voiceChannels', function(self, key, value)
	return self._voice_channels:getAll(key, value)
end)

function Guild:getVoiceChannel(key, value)
	return self._voice_channels:get(key, value)
end

function Guild:findVoiceChannel(predicate)
	return self._voice_channels:find(predicate)
end

function Guild:findVoiceChannels(predicate)
	return self._voice_channels:findAll(predicate)
end

-- roles --

get('roleCount', function(self)
	return self._roles._count
end)

get('roles', function(self, key, value)
	return self._roles:getAll(key, value)
end)

function Guild:getRole(key, value)
	return self._roles:get(key, value)
end

function Guild:findRole(predicate)
	return self._roles:find(predicate)
end

function Guild:findRoles(predicate)
	return self._roles:findAll(predicate)
end

-- members --

get('memberCount', function(self)
	return self._members._count
end)

get('members', function(self, key, value)
	return self._members:getAll(key, value)
end)

function Guild:getMember(key, value)
	return self._members:get(key, value)
end

function Guild:findMember(predicate)
	return self._members:find(predicate)
end

function Guild:findMembers(predicate)
	return self._members:findAll(predicate)
end

-- members --

get('voiceStateCount', function(self)
	return self._voice_states._count
end)

get('voiceStates', function(self, key, value)
	return self._voice_states:getAll(key, value)
end)

function Guild:getVoiceState(key, value)
	return self._voice_states:get(key, value)
end

function Guild:findVoiceState(predicate)
	return self._voice_states:find(predicate)
end

function Guild:findVoiceStates(predicate)
	return self._voice_states:findAll(predicate)
end

-- messages --

get('messageCount', function(self)
	local n = 0
	for channel in self._text_channels:iter() do
		n = n + channel._messages._count
	end
	return n
end)

get('messages', function(self, key, value)
	return wrap(function()
		for channel in self._text_channels:iter() do
			for message in channel._messages:iter() do
				yield(message)
			end
		end
	end)
end)

function Guild:getMessage(key, value)
	for channel in self._text_channels:iter() do
		local message = channel._messages:get(predicate)
		if message then return message end
	end
end

function Guild:findMessage(predicate)
	for channel in self._text_channels:iter() do
		local message = channel._messages:find(predicate)
		if message then return message end
	end
end

function Guild:findMessages(predicate)
	return wrap(function()
		for channel in self._text_channels:iter() do
			for message in channel._messages:findAll(predicate) do
				yield(message)
			end
		end
	end)
end

return Guild
