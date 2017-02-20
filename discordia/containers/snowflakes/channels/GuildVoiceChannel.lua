local GuildChannel = require('./GuildChannel')
local timer = require('timer')

local clamp = math.clamp
local setTimeout = timer.setTimeout
local running, yield, wrap = coroutine.running, coroutine.yield, coroutine.wrap

local GuildVoiceChannel, property, method, cache = class('GuildVoiceChannel', GuildChannel)
GuildVoiceChannel.__description = "Represents a Discord guild voice channel."

function GuildVoiceChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	GuildVoiceChannel._update(self, data)
end

function GuildVoiceChannel:_update(data)
	GuildChannel._update(self, data)
end

local function setBitrate(self, bitrate)
	bitrate = bitrate and clamp(bitrate, 8000, self._parent._vip and 128000 or 96000) or 64000
	local success, data = self._parent._parent._api:modifyChannel(self._id, {bitrate = bitrate})
	if success then self._bitrate = data.bitrate end
	return success
end

local function setUserLimit(self, limit)
	limit = limit and clamp(limit, 0, 99) or 0
	local success, data = self._parent._parent._api:modifyChannel(self._id, {user_limit = limit})
	if success then self._user_limit = data.user_limit end
	return success
end

local function join(self)

	local guild = self._parent
	local client = guild._parent
	local voice = client._voice

	if not voice._opus then return client:warning('Cannot join voice channel: libopus not loaded.') end
	if not voice._sodium then return client:warning('Cannot join voice channel: libsodium not loaded.') end

	local guild_id = guild._id

	local joining = voice._joining[guild_id]

	if joining then	return client:warning('Cannot join voice channel: Prior request not yet fulfilled.') end

	local connection = voice._connections[guild_id]

	if connection then
		if connection._channel == self then return connection end
		connection._channel = self
	end

	voice._joining[guild_id] = running()
	setTimeout(5000, function()
		if voice._joining[guild_id] then
			client:warning('Failed to join voice channel: ' .. self._id)
			return voice:_resumeJoin(guild_id)
		end
	end)

	return yield(client._sockets[guild.shardId]:joinVoiceChannel(guild_id, self._id))

end

local function leave(self)

	local guild = self._parent
	local client = guild._parent
	local voice = client._voice

	local guild_id = guild._id
	local connection = voice._connections[guild_id]

	if not connection then return true end

	voice._leaving[guild_id] = running()
	setTimeout(10000, function()
		if voice._leaving[guild_id] then
			client:warning('Failed to leave voice channel: ' .. self._id)
			return voice:_resumeLeave(guild_id, false)
		end
	end)

	client._sockets[guild.shardId]:joinVoiceChannel(guild_id)
	return yield(connection._socket:disconnect())

end

local function getConnection(self)
	return self._parent._connection
end

local function getMemberCount(self)
	local n = 0
	local id = self._id
	local guild = self._parent
	for _, state in pairs(guild._voice_states) do
		if state.channel_id == id then
			n = n + 1
		end
	end
	return n
end

local function getMember(self, key, value)
	local members = self._parent._members
	if key == nil and value == nil then return nil end
	if value == nil then
		value = key
		key = members._key
	end
	local id = self._id
	local guild = self._parent
	for _, state in pairs(guild._voice_states) do
		if state.channel_id == id then
			local member = guild:getMember(state.user_id)
			if member and member[key] == value then
				return member
			end
		end
	end
end

local function getMembers(self, key, value)
	local id = self._id
	local guild = self._parent
	return wrap(function()
		for _, state in pairs(guild._voice_states) do
			if state.channel_id == id then
				local member = guild:getMember(state.user_id)
				if member and member[key] == value then
					yield(member)
				end
			end
		end
	end)
end

local function findMember(self, predicate)
	local id = self._id
	local guild = self._parent
	for _, state in pairs(guild._voice_states) do
		if state.channel_id == id then
			local member = guild:getMember(state.user_id)
			if member and predicate(member) then
				return member
			end
		end
	end
end

local function findMembers(self, predicate)
	local id = self._id
	local guild = self._parent
	return wrap(function()
		for _, state in pairs(guild._voice_states) do
			if state.channel_id == id then
				local member = guild:getMember(state.user_id)
				if member and predicate(member) then
					yield(member)
				end
			end
		end
	end)
end

property('bitrate', '_bitrate', setBitrate, '[number]', "Channel bitrate in bits per seconds (8000 to 96000 or 128000 for VIP guilds, default: 64000)")
property('userLimit', '_user_limit', setUserLimit, '[number]', "Limit to the number of users allowed in the channel (use 0 for infinite, default: 0)")
property('connection', getConnection, nil, 'VoiceConnection', "The handle for this channel's voice connection, if one exists")

method('join', join, nil, "Joins the voice channel. A connection, either a new or old one, is returned if successful.")
method('leave', leave, nil, "Leaves the voice channel. A boolean is returned to indicate success.")

cache('Member', getMemberCount, getMember, getMembers, findMember, findMembers)

return GuildVoiceChannel
