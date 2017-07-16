local json = require('json')

local Cache = require('iterables/Cache')
local ArrayIterable = require('iterables/ArrayIterable')
local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')
local Resolver = require('client/Resolver')

local format = string.format

local Message = require('class')('Message', Snowflake)
local get = Message.__getters

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:_insert(data.author)
	self._timestamp = nil -- waste of space; can be calculated from Snowflake ID
	if data.reactions and #data.reactions > 0 then
		self._reactions = Cache(data.reactions, Reaction, self)
	end
	return self:_loadMore(data)
end

function Message:__tostring()
	return format('%s: %s', self.__name, self._content)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

local function parseUserMentions(mentions, cache)
	if #mentions == 0 then return end
	for i, user in ipairs(mentions) do
		mentions[i] =  cache:_insert(user)
	end
	return mentions
end

local function parseChannelMentions(content)
	if not content:find('<#') then return end
	local ids = {}
	for id in content:gmatch('<#(%d-)>') do
		table.insert(ids, id)
	end
	return ids
end

function Message:_loadMore(data)

	if data.mentions then
		local mentions = parseUserMentions(data.mentions, self.client._users)
		if self._mentioned_users then
			self._mentioned_users._array = mentions
		else
			self._mentioned_users_raw = mentions
		end
	end

	if data.mention_roles then
		local mentions = #data.mention_roles > 0 and data.mention_roles or nil
		if self._mentioned_roles then
			self._mentioned_roles._array = mentions
		else
			self._mentioned_roles_raw = mentions
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

function Message:_addReaction(data, id)

	local reactions = self._reactions

	if not reactions then
		reactions = Cache({}, Reaction, self)
		self._reactions = reactions
	end

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	if reaction then
		reaction._count = reaction._count + 1
		if id == self.client._user._id then
			reaction._me = true
		end
	else
		data.me = id == self.client._user._id
		data.count = 1
		reaction = reactions:_insert(data)
	end
	return reaction

end

function Message:_removeReaction(data, id)

	local reactions = self._reactions

	local emoji = data.emoji
	local k = emoji.id or emoji.name
	local reaction = reactions:get(k)

	reaction._count = reaction._count - 1
	if id == self.client._user._id then
		reaction._me = false
	end

	if reaction._count == 0 then
		reactions:_delete(k)
	end

	return reaction

end

function Message:_modify(payload)
	local data, err = self.client._api:editMessage(self._parent._id, self._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Message:setContent(content)
	return self:_modify({content = content or json.null})
end

function Message:setEmbed(embed)
	return self:_modify({embed = embed or json.null})
end

function Message:pin()
	local data, err = self.client._api:addPinnedChannelMessage(self._parent._id, self._id)
	if data then
		self._pinned = true
		return true
	else
		return false, err
	end
end

function Message:unpin()
	local data, err = self.client._api:deletePinnedChannelMessage(self._parent._id, self._id)
	if data then
		self._pinned = false
		return true
	else
		return false, err
	end
end

function Message:react(emoji) -- TODO: return new reaction?
	emoji = Resolver.emoji(emoji)
	local data, err = self.client._api:createReaction(self._parent._id, self._id, emoji)
	if data then
		return true
	else
		return false, err
	end
end

function Message:clearReactions()
	local data, err = self.client._api:deleteAllReactions(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

function Message:delete()
	local data, err = self.client._api:deleteMessage(self._parent._id, self._id)
	if data then
		return true
	else
		return false, err
	end
end

function get.reactions(self)
	if not self._reactions then
		self._reactions = Cache({}, Reaction, self)
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
		local guild = self._parent.guild
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
		local client = self.client
		self._mentioned_channels = ArrayIterable(ids, function(id)
			local guild = client._channel_map[id]
			if guild then
				return guild._text_channels:get(id) or guild._voice_channels:get(id)
			else
				return client._private_channels:get(id) or client._group_channels:get(id)
			end
		end)
	end
	return self._mentioned_channels
end

function get.pinned(self)
	return self._pinned
end

function get.tts(self)
	return self._tts
end

function get.nonce(self)
	return self._nonce
end

function get.editedTimestamp(self)
	return self._edited_timestamp
end

function get.content(self)
	return self._content
end

function get.author(self)
	return self._author
end

function get.channel(self)
	return self._parent
end

function get.type(self)
	return self._type
end

function get.embed(self)
	return self._embeds and self._embeds[1]
end

function get.attachment(self)
	return self._attachments and self._attachments[1]
end

function get.embeds(self)
	return self._embeds
end

function get.attachments(self)
	return self._attachments
end

return Message
