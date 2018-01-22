local json = require('json')
local constants = require('constants')
local Cache = require('iterables/Cache')
local ArrayIterable = require('iterables/ArrayIterable')
local Snowflake = require('containers/abstract/Snowflake')
local Reaction = require('containers/Reaction')
local Resolver = require('client/Resolver')

local insert = table.insert
local null = json.null

local Message, get = require('class')('Message', Snowflake)

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	self._author = self.client._users:_insert(data.author)
	self._timestamp = nil -- waste of space; can be calculated from Snowflake ID
	if data.reactions and #data.reactions > 0 then
		self._reactions = Cache(data.reactions, Reaction, self)
	end
	return self:_loadMore(data)
end

function Message:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

local function parseMentions(content)

	local i = content:find('<')
	if not i then return end
	local j = content:find('>', i)
	if not j then return end

	local users, roles, channels, emojis = {}, {}, {}, {}
	local seen = {}

	for symbol, id in content:gmatch('<.-(%p+)(%d+)>') do
		if not seen[id] then
			if symbol == '@&' then
				insert(roles, id)
			elseif symbol == '@' or symbol == '@!' then
				insert(users, id)
			elseif symbol == '#' then
				insert(channels, id)
			elseif symbol == ':' then
				insert(emojis, id)
			end
			seen[id] = true
		end
	end
	return users, roles, channels, emojis

end

function Message:_loadMore(data)

	if data.mentions then
		self.client._users:_load(data.mentions)
	end

	if data.content then
		local users, roles, channels, emojis = parseMentions(data.content)
		if self._mentioned_users then
			self._mentioned_users._array = users
		else
			self._mentioned_users_raw = users
		end
		if self._mentioned_roles then
			self._mentioned_roles._array = roles
		else
			self._mentioned_roles_raw = roles
		end
		if self._mentioned_channels then
			self._mentioned_channels._array = channels
		else
			self._mentioned_channels_raw = channels
		end
		if self._mentioned_emojis then
			self._mentioned_emojis._array = emojis
		else
			self._mentioned_emojis_raw = emojis
		end
		self._clean_content = nil
	end

	if data.embeds then
		self._embeds = #data.embeds > 0 and data.embeds or nil
	end

	if data.attachments then
		self._attachments = #data.attachments > 0 and data.attachments or nil
	end

end

function Message:_addReaction(d)

	local reactions = self._reactions

	if not reactions then
		reactions = Cache({}, Reaction, self)
		self._reactions = reactions
	end

	local emoji = d.emoji
	local k = emoji.id ~= null and emoji.id or emoji.name
	local reaction = reactions:get(k)

	if reaction then
		reaction._count = reaction._count + 1
		if d.user_id == self.client._user._id then
			reaction._me = true
		end
	else
		d.me = d.user_id == self.client._user._id
		d.count = 1
		reaction = reactions:_insert(d)
	end
	return reaction

end

function Message:_removeReaction(d)

	local reactions = self._reactions

	local emoji = d.emoji
	local k = emoji.id ~= null and emoji.id or emoji.name
	local reaction = reactions:get(k)

	if not reaction then return nil end -- uncached reaction?

	reaction._count = reaction._count - 1
	if d.user_id == self.client._user._id then
		reaction._me = false
	end

	if reaction._count == 0 then
		reactions:_delete(k)
	end

	return reaction

end

function Message:_setOldContent(d)
	local ts = d.edited_timestamp
	if not ts then return end
	local old = self._old
	if old then
		old[ts] = old[ts] or self._content
	else
		self._old = {[ts] = self._content}
	end
end

function Message:_modify(payload)
	local data, err = self.client._api:editMessage(self._parent._id, self._id, payload)
	if data then
		self:_setOldContent(data)
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Message:setContent(content)
	return self:_modify({content = content or null})
end

function Message:setEmbed(embed)
	return self:_modify({embed = embed or null})
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

function Message:addReaction(emoji)
	emoji = Resolver.emoji(emoji)
	local data, err = self.client._api:createReaction(self._parent._id, self._id, emoji)
	if data then
		return true
	else
		return false, err
	end
end

function Message:removeReaction(emoji, id)
	emoji = Resolver.emoji(emoji)
	local data, err
	if id then
		id = Resolver.userId(id)
		data, err = self.client._api:deleteUserReaction(self._parent._id, self._id, emoji, id)
	else
		data, err = self.client._api:deleteOwnReaction(self._parent._id, self._id, emoji)
	end
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
		local cache = self._parent._messages
		if cache then
			cache:_delete(self._id)
		end
		return true
	else
		return false, err
	end
end

function Message:reply(content)
	return self._parent:send(content)
end

function get.reactions(self)
	if not self._reactions then
		self._reactions = Cache({}, Reaction, self)
	end
	return self._reactions
end

function get.mentionedUsers(self)
	if not self._mentioned_users then
		local users = self.client._users
		self._mentioned_users = ArrayIterable(self._mentioned_users_raw, function(id)
			return users:get(id)
		end)
		self._mentioned_users_raw = nil
	end
	return self._mentioned_users
end

function get.mentionedRoles(self)
	if not self._mentioned_roles then
		local client = self.client
		self._mentioned_roles = ArrayIterable(self._mentioned_roles_raw, function(id)
			local guild = client._role_map[id]
			return guild and guild._roles:get(id) or nil
		end)
		self._mentioned_roles_raw = nil
	end
	return self._mentioned_roles
end

function get.mentionedEmojis(self)
	if not self._mentioned_emojis then
		local client = self.client
		self._mentioned_emojis = ArrayIterable(self._mentioned_emojis_raw, function(id)
			local guild = client._emoji_map[id]
			return guild and guild._emojis:get(id)
		end)
		self._mentioned_emojis_raw = nil
	end
	return self._mentioned_emojis
end

function get.mentionedChannels(self)
	if not self._mentioned_channels then
		local client = self.client
		self._mentioned_channels = ArrayIterable(self._mentioned_channels_raw, function(id)
			local guild = client._channel_map[id]
			if guild then
				return guild._text_channels:get(id) or guild._voice_channels:get(id) or guild._categories:get(id)
			else
				return client._private_channels:get(id) or client._group_channels:get(id)
			end
		end)
		self._mentioned_channels_raw = nil
	end
	return self._mentioned_channels
end

local usersMeta = {__index = function(_, k) return '@' .. k end}
local rolesMeta = {__index = function(_, k) return '@' .. k end}
local channelsMeta = {__index = function(_, k) return '#' .. k end}
local everyone = '@' .. constants.ZWSP .. 'everyone'
local here = '@' .. constants.ZWSP .. 'here'

function get.cleanContent(self)

	if not self._clean_content then

		local content = self._content
		local guild = self.guild

		local users = setmetatable({}, usersMeta)
		for user in self.mentionedUsers:iter() do
			local member = guild and guild._members:get(user._id)
			users[user._id] = '@' .. (member and member._nick or user._username)
		end

		local roles = setmetatable({}, rolesMeta)
		for role in self.mentionedRoles:iter() do
			roles[role._id] = '@' .. role._name
		end

		local channels = setmetatable({}, channelsMeta)
		for channel in self.mentionedChannels:iter() do
			channels[channel._id] = '#' .. channel._name
		end

		self._clean_content = content
			:gsub('<@!?(%d+)>', users)
			:gsub('<@&(%d+)>', roles)
			:gsub('<#(%d+)>', channels)
			:gsub('<a?(:.+:)%d+>', '%1')
			:gsub('@everyone', everyone)
			:gsub('@here', here)

	end

	return self._clean_content

end

function get.mentionsEveryone(self)
	return self._mention_everyone
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

function get.oldContent(self)
	return self._old
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

function get.guild(self)
	return self._parent.guild
end

function get.member(self)
	local guild = self.guild
	return guild and guild._members:get(self._author._id)
end

return Message
