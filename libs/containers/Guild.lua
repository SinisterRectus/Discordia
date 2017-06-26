local Snowflake = require('containers/abstract/Snowflake')
local Cache = require('utils/Cache')

local Role = require('containers/Role')
local Emoji = require('containers/Emoji')
local Member = require('containers/Member')
local GuildTextChannel = require('containers/GuildTextChannel')
local GuildVoiceChannel = require('containers/GuildVoiceChannel')

local enums = require('enums')
local channelType = enums.channelType
local floor = math.floor

local Guild = require('class')('Guild', Snowflake)
local get = Guild.__getters

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._roles = Cache(Role, self)
	self._emojis = Cache(Emoji, self)
	self._members = Cache(Member, self)
	self._text_channels = Cache(GuildTextChannel, self)
	self._voice_channels = Cache(GuildVoiceChannel, self)
	self._voice_states = {}
	if not data.unavailable then
		return self:_makeAvailable(data)
	end
end

function Guild:_makeAvailable(data)

	self._roles:merge(data.roles)
	self._emojis:merge(data.emojis)

	local voice_states = self._voice_states
	for _, state in ipairs(data.voice_states) do
		voice_states[state.user_id] = state
	end

	local text_channels = self._text_channels
	local voice_channels = self._voice_channels
	for _, channel in ipairs(data.channels) do
		if channel.type == channelType.text then
			text_channels:insert(channel)
		elseif channel.type == channelType.voice then
			voice_channels:insert(channel)
		end
	end

	self._features = data.features -- raw table of strings

	return self:_loadMembers(data)

end

function Guild:_loadMembers(data)
	local members = self._members
	members:merge(data.members)
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

function Guild:requestMembers()
	local shard = self.client._shards[self.shardId]
	if shard._loading then
		shard._loading.chunks[self._id] = true
	end
	return shard:requestGuildMembers(self._id)
end

function get.shardId(self)
	return floor(self._id / 2^22) % self.client._shard_count
end

return Guild
