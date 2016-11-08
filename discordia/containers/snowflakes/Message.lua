local Snowflake = require('../Snowflake')

local insert = table.insert
local format, char = string.format, string.char
local wrap, yield = coroutine.wrap, coroutine.yield

local Message, property, method = class('Message', Snowflake)
Message.__description = "Represents a Discord text channel message."

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	self._author = client._users:get(data.author.id) or client._users:new(data.author)
	self:_update(data)
end

function Message:__tostring()
	return format('%s: %s', self.__name, self._content)
end

function Message:_update(data)
	Snowflake._update(self, data)
	if data.mentions then
		local channel = self._parent
		local client = channel._parent._parent or channel._parent
		local users = client._users
		local mentions = {}
		for _, user_data in ipairs(data.mentions) do
			insert(mentions, users:get(user_data.id) or users:new(user_data))
		end
		self._mentions = mentions
	end
	if data.mention_roles ~= nil then self._mention_roles = data.mention_roles end
	self._embeds = data.embeds -- TODO: parse embeds
	self._attachments = data.attachments -- TODO: parse attachments
end

local function setContent(self, content)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success, data = client._api:editMessage(channel._id, self._id, {content = content})
	if success then self._content = data.content end
	return success
end

local function getCleanContent(self)
	local content = self.content
	local parent = self._parent
	local guild = not parent._is_private and parent._parent
	for user in self.mentionedUsers do
		local name = guild and user:getMembership(guild).name or user._username
		content = content:gsub(format('<@!?%s>', user._id), '@' .. name)
	end
	for role in self.mentionedRoles do
		content = content:gsub(format('<@&%s>', role._id), '@' .. role._name)
	end
	for channel in self.mentionedChannels do
		content = content:gsub(format('<#%s>', channel._id), '#' .. channel._name)
	end
	content = content:gsub('@everyone', format('@%severyone', char(0)))
	content = content:gsub('@here', format('@%shere', char(0)))
	return content
end

local function getMember(self)
	local channel = self._parent
	if channel._is_private then return end
	return self._author:getMembership(channel._parent)
end

local function getGuild(self)
	local channel = self._parent
	if not channel._is_private then return channel._parent end
end

local function getMentionedUsers(self)
	local mentions, k, v = self._mentions
	if not mentions then return function() end end
	return function()
		k, v = next(mentions, k)
		return v
	end
end

local function getMentionedRoles(self)
	return wrap(function()
		local guild = self._parent._parent
		if self._mention_everyone then
			yield(guild.defaultRole)
		end
		if self._mention_roles then
			local roles = guild._roles
			for _, id in ipairs(self._mention_roles) do
				local role = roles:get(id)
				if role then yield(role) end
			end
		end
	end)
end

local function getMentionedChannels(self)
	return wrap(function()
		local parent = self._parent._parent
		for id in self._content:gmatch('<#(.-)>') do
			local channel = parent:getTextChannel(id)
			if channel then yield(channel) end
		end
	end)
end

local function mentionsObject(self, obj)
	local type = obj.__name
	if type == 'Member' then
		obj = obj._user
		for user in self:getMentionedUsers() do
			if obj == user then return true end
		end
	elseif type == 'User' then
		for user in self:getMentionedUsers() do
			if obj == user then return true end
		end
	elseif type == 'Role' then
		for role in self:getMentionedRoles() do
			if obj == role then return true end
		end
	elseif type == 'GuildTextChannel' then
		for channel in self:getMentionedChannels() do
			if obj == channel then return true end
		end
	end
	return false
end

local function reply(self, ...)
	return self._parent:sendMessage(...)
end

local function pin(self)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success = client._api:addPinnedChannelMessage(channel._id, self._id)
	if success then self._pinned = true end
	return success
end

local function unpin(self)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success = client._api:deletePinnedChannelMessage(channel._id, self._id)
	if success then self._pinned = false end
	return success
end

local function delete(self)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	return (client._api:deleteMessage(channel._id, self._id))
end

property('content', '_content', setContent, 'string', "The raw message text")
property('cleanContent', getCleanContent, nil, 'string', "The message text with sanitized mentions")
property('tts', '_tts', nil, 'boolean', "Whether the message is a TTS one")
property('pinned', '_pinned', nil, 'boolean', "Whether the message is pinned")
property('timestamp', '_timestamp', nil, 'string', "Date and time that the message was created")
property('editedTimestamp', '_edited_timestamp', nil, 'string', "Date and time that the message was edited")
property('channel', '_parent', nil, 'TextChannel', "The channel in which the message exists (GuildTextChannel or PrivateChannel)")
property('author', '_author', nil, 'User', "The user object representing the message's author")
property('member', getMember, nil, 'Member', "The member object for the author (does not exist for private channels)")
property('guild', getGuild, nil, 'Guild', "The guild in which the message exists (does not exist for private channels)")
property('mentionedUsers', getMentionedUsers, nil, 'function', "An iterator for known Users that are mentioned in the message")
property('mentionedRoles', getMentionedRoles, nil, 'function', "An iterator for known Roles that are mentioned in the message")
property('mentionedChannels', getMentionedChannels, nil, 'function', "An iterator for known GuildTextChannels that are mentioned in the message")

method('reply', reply, 'content[, mentions, tts, nonce]', "Shortcut for `message.channel:sendMessage`.")
method('pin', pin, nil, "Adds the message to the channel's pinned messages.")
method('unpin', unpin, nil, "Removes the message from the channel's pinned messages.")
method('delete', delete, nil, "Permanently deletes the message from the channel.")
method('mentionsObject', mentionsObject, 'obj', "Returns a boolean indicating whether the provided object was mentioned in the message.")

return Message
