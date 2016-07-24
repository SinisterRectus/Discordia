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
	-- TODO: mentions, embeds, attachments
end

return Message
