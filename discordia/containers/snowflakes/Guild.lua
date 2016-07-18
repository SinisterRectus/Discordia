local Snowflake = require('../Snowflake')
local Role = require('./Role')
local Member = require('./Member')
local GuildTextChannel = require('./channels/GuildTextChannel')
local GuildVoiceChannel = require('./channels/GuildVoiceChannel')
local VoiceState = require('../VoiceState')
local Cache = require('../../utils/Cache')
local RateLimiter = require('../../utils/RateLimiter')

local Guild, accessors = class('Guild', Snowflake)

accessors.me = function(self) return self.members:get(self.client.user.id) end
accessors.owner = function(self) return self.members:get(self.ownerId) end
accessors.afkChannel = function(self) return self.voiceChannels:get(self.afkChannelId) end
accessors.defaultRole = function(self) return self.roles:get(self.id) end
accessors.defaultChannel = function(self) return self.textChannels:get(self.id) end

function Guild:__init(data, parent)
	Snowflake.__init(self, data, parent)
	if data.unavailable then
		self.unavailable = true
	else
		self:makeAvailable(data)
	end
end

function Guild:initRateLimiters()
	self.client.api.limiters.perGuild[self.id] = {
		createMessage = RateLimiter(5, 5000),
		deleteMessage = RateLimiter(5, 1000),
		bulkDelete = RateLimiter(1, 1000),
		guildMember = RateLimiter(10, 10000),
		memberNick = RateLimiter(1, 1000),
	}
end

function Guild:makeAvailable(data)

	self.unavailable = false

	self.large = data.large
	self.joinedAt = data.joined_at
	self.memberCount = data.member_count

	self.roles = Cache(data.roles or {}, Role, 'id', self)
	self.members = Cache(data.members or {}, Member, 'id', self)
	self.voiceStates = Cache(data.voice_states or {}, VoiceState, 'sessionId', self)
	self.textChannels = Cache({}, GuildTextChannel, 'id', self)
	self.voiceChannels = Cache({}, GuildVoiceChannel, 'id', self)

	if data.presences then
		self:loadMemberPresences(data.presences)
	end

	if data.channels then
		for _, data in ipairs(data.channels) do
			if data.type == 'text' then
				self.textChannels:new(data)
			elseif data.type == 'voice' then
				self.voiceChannels:new(data)
			end
		end
	end

	if self.large and self.client.options.fetchMembers then
		self:requestMembers()
	end

	self:update(data)

end

function Guild:update(data)
	self.name = data.name
	self.icon = data.icon
	self.splash = data.splash
	self.region = data.region
	self.ownerId = data.owner_id
	self.mfaLevel = data.mfa_level
	self.afkTimeout = data.afk_timeout
	self.afkChannelId = data.afk_channel_id
	self.verificationLevel = data.verification_level
	-- self.emojis = data.emojis -- TODO
	-- self.features = data.features -- TODO
end

function Guild:loadMemberPresences(data)
	for _, presence in ipairs(data) do
		local member = self.members:get(presence.user.id)
		member:createPresence(presence)
	end
end

function Guild:updateMemberPresence(data)
	local member = self.members:get(data.user.id)
	if member then
		member:updatePresence(data)
	else
		member = self.members:new(data)
		member:createPresence(data)
	end
	return member
end

function Guild:requestMembers()
	self.client.socket:requestGuildMembers(self.id)
	if self.client.loading then
		self.client.loading.chunks[self.id] = true
	end
end

-- convenience accessors --

function Guild:getRoleById(id)
	return self.roles:get(id)
end

function Guild:getChannelById(id)
	return self:getTextChannelById(id) or self:getVoiceChannelById(id) or nil
end

function Guild:getTextChannelById(id)
	return self.textChannels:get(id)
end

function Guild:getVoiceChannelById(id)
	return self.voiceChannels:get(id)
end

function Guild:getMemberById(id)
	return self.members:get(id)
end

function Guild:getMemberByName(name)
	return self.members:get('name', name)
end

function Guild:getVoiceStateById(sessionId)
	return self.voiceStates:get(sessionId)
end

-- convenience iterators --

function Guild:getRoles()
	return self.roles:iter()
end

function Guild:getChannels()
	return coroutine.wrap(function()
		for channel in self:getTextChannels() do
			coroutine.yield(channel)
		end
		for channel in self:getVoiceChannels() do
			coroutine.yield(channel)
		end
	end)
end

function Guild:getTextChannels()
	return self.textChannels:iter()
end

function Guild:getVoiceChannels()
	return self.voiceChannels:iter()
end

function Guild:getMembers()
	return self.members:iter()
end

function Guild:getVoiceStates()
	return self.voiceStates:iter()
end

return Guild
