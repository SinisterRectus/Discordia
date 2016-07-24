local Snowflake = require('../Snowflake')
local Cache = require('../../utils/Cache')
local Container = require('../../utils/Container')

local Message, accessors = class('Message', Snowflake)

accessors.channel = function(self) return self.parent end
accessors.guild = function(self) return self.parent.guild end
-- guild does not exist for messages in private channels

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self.author = self.client.users:get(data.author.id) or self.client.users:new(data.author)
	self:update(data)
end

function Message:__tostring()
	return string.format('%s: %s', self.__name, self.content)
end

function Message:update(data)
	self.tts = data.tts == nil and self.tts or data.tts
	self.type = data.type == nil and self.type or data.type
	self.pinned = data.pinned == nil and self.pinned or data.pinned
	self.content = data.content == nil and self.content or data.content
	self.editedTimestamp = data.edited_timestamp == nil and self.editedTimestamp or data.edited_timestamp
	self.mentionEveryone = data.mention_everyone == nil and self.mentionEveryone or data.mention_everyone
	self:parseMentions(data)
	-- TODO: mentions, embeds, attachments
end

function Message:parseMentions(data)
	local mentions = {users = {}, roles = {}, channels = {}}
	if data.mentions and #data.mentions > 0 then
		for _, data in ipairs(data.mentions) do
			mentions.users[data.id] = self.client.users:get(data.id) or self.client.users:new(data)
		end
	end
	if data.mention_roles and #data.mention_roles > 0 then
		for _, id in ipairs(data.mention_roles) do
			mentions.roles[id] = self.guild.roles:get(id)
		end
	end
	for mention in self.content:gmatch('<#.->') do
		local channel = self.guild.textChannels:get(mention:sub(3, -2))
		if channel then mentions.channels[channel.id] = channel end
	end
	if self.mentionEveryone then
		mentions.roles[self.guild.id] = self.guild.defaultRole
	end
	self.mentions = mentions
end

return Message
