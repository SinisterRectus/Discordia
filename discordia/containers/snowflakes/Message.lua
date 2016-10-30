local Snowflake = require('../Snowflake')
local Cache = require('../../utils/Cache')
local Container = require('../../utils/Container')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Message, accessors = class('Message', Snowflake)

accessors.channel = function(self) return self.parent end
accessors.guild = function(self) return self.parent.guild end
-- guild does not exist for messages in private channels

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.author = self.client.users:get(data.author.id) or self.client.users:new(data.author)
	self:_update(data)
end

function Message:__tostring()
	return format('%s: %s', self.__name, self.content)
end

function Message:_update(data)
	self.tts = data.tts == nil and self.tts or data.tts
	self.type = data.type == nil and self.type or data.type
	self.pinned = data.pinned == nil and self.pinned or data.pinned
	self.content = data.content == nil and self.content or data.content
	self.editedTimestamp = data.edited_timestamp == nil and self.editedTimestamp or data.edited_timestamp
	self.mentionEveryone = data.mention_everyone == nil and self.mentionEveryone or data.mention_everyone
	self.mentionRoles = data.mention_roles == nil and self.mentionRoles or data.mention_roles
	if data.mentions then
		local mentions = {}
		for _, data in ipairs(data.mentions) do
			insert(mentions, self.client.users:get(data.id) or self.client.users:new(data))
		end
		self.mentions = mentions
	end
	-- TODO: embeds, attachments
end

function Message:getMentionedUsers()
	local mentions, k, v = self.mentions
	if not mentions then return function() end end
	return function()
		k, v = next(mentions, k)
		return v
	end
end

function Message:getMentionedRoles()
	return wrap(function()
		local guild = self.guild
		if self.mentionEveryone then
			yield(guild.defaultRole)
		end
		if not self.mentionRoles then return end
		local roles = guild.roles
		for _, id in ipairs(self.mentionRoles) do
			local role = roles:get(id)
			if role then yield(role) end
		end
	end)
end

function Message:getMentionedChannels()
	return wrap(function()
		local textChannels = self.guild.textChannels
		for id in self.content:gmatch('<#(.-)>') do
			local channel = textChannels:get(id)
			if channel then yield(channel) end
		end
	end)
end

function Message:mentionsUser(user)
	for obj in self:getMentionedUsers() do
		if obj == user then return true end
	end
	return false
end

function Message:mentionsRole(role)
	for obj in self:getMentionedRoles() do
		if obj == role then return true end
	end
	return false
end

function Message:mentionsChannel(channel)
	for obj in self:getMentionedChannels() do
		if obj == channel then return true end
	end
	return false
end

function Message:setContent(content)
	local success, data = self.client.api:editMessage(self.parent.id, self.id, {content = content})
	if success then self.content = data.content end
	return success
end

function Message:pin()
	local success, data = self.client.api:addPinnedChannelMessage(self.parent.id, self.id)
	if success then self.pinned = true end
	return success
end

function Message:unpin()
	local success, data = self.client.api:deletePinnedChannelMessage(self.parent.id, self.id)
	if success then self.pinned = false end
	return success
end

function Message:delete()
	local success, data = self.client.api:deleteMessage(self.parent.id, self.id)
	return success
end

return Message
