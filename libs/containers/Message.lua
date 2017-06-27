local Cache = require('iterables/Cache')
local ArrayIterable = require('iterables/ArrayIterable')
local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')

local enums = require('enums')
local channelType = enums.channelType

local Message = require('class')('Message', Snowflake)
local get = Message.__getters

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:_insert(data.author)
	if data.reactions and #data.reactions > 0 then
		self._reactions = Cache(Reaction, self)
		self._reactions:_load(data.reactions)
	end
	return self:_loadMore(data)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

local function parseUserMentions(mentions, users)
	for i, user in ipairs(mentions) do
		mentions[i] =  users:_insert(user)
	end
	return mentions
end

local function parseChannelMentions(content)
	local ids = {}
	for id in content:gmatch('<#(%d-)>') do
		table.insert(ids, id)
	end
	return ids
end

function Message:_loadMore(data)

	if data.mentions then
		if self._mentioned_users then
			self._mentioned_users._array = parseUserMentions(data.mentions, self.client._users)
		elseif #data.mentions > 0 then
			self._mentioned_users_raw = parseUserMentions(data.mentions, self.client._users)
		else
			self._mentioned_users_raw = nil
		end
	end

	if data.mention_roles then
		if self._mentioned_roles then
			self._mentioned_roles._array = data.mention_roles
		elseif #data.mention_roles > 0 then
			self._mentioned_roles_raw = data.mention_roles
		else
			self._mentioned_roles_raw = nil
		end
	end

	if data.content and self._mentioned_channels then
		self._mentioned_channels._array = parseChannelMentions(data.content)
	end

	if data.embeds then
		self._embeds = #data.embeds > 0 and data.embeds or nil
	end

	if data.attachments then
		self._attachments = #data.attachments > 0 and data.attachments or nil
	end

end

function Message:_addReaction(data, user)

	local reactions = self._reactions

	if not reactions then
		reactions = Cache(Reaction, self)
		self._reactions = reactions
	end

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	if reaction then
		reaction._count = reaction._count + 1
		if user == self.client._user then
			reaction._me = true
		end
	else
		data.me = user == self.client._user
		data.count = 1
		reaction = reactions:_insert(data)
	end
	return reaction

end

function Message:_removeReaction(data, user)

	local reactions = self._reactions

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	reaction._count = reaction._count - 1
	if user == self.client._user then
		reaction._me = false
	end

	if reaction._count == 0 then
		reactions:delete(k)
	end

	return reaction

end

function get.reactions(self)
	if not self._reactions then
		self._reactions = Cache(Reaction, self)
	end
	return self._reactions
end

function get.mentionedUsers(self)
	if not self._mentioned_users then
		self._mentioned_users = ArrayIterable(self._mentioned_users_raw)
		self._mentioned_users_raw = nil
	end
	return self._mentioned_users
end

function get.mentionedRoles(self)
	if not self._mentioned_roles then
		local channel = self._parent
		local guild = channel._type == channelType.text and channel._parent
		local roles = guild and guild._roles
		self._mentioned_roles = ArrayIterable(self._mentioned_roles_raw, function(id)
			return roles:get(id)
		end)
		self._mentioned_roles_raw = nil
	end
	return self._mentioned_roles
end

function get.mentionedChannels(self)
	if not self._mentioned_channels then
		local ids = parseChannelMentions(self._content)
		self._mentioned_channels = ArrayIterable(ids, function()
			-- TODO: get channel
		end)
	end
	return self._mentioned_channels
end

return Message
