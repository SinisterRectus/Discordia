local Snowflake = require('../Snowflake')
local Container = require('../../utils/Container')

local insert = table.insert
local format = string.format
local wrap, yield = coroutine.wrap, coroutine.yield

local Message, property = class('Message', Snowflake)

function Message:__init(data, parent)
	Snowflake.__init(self, data, parent)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	self._author = client._users:get(data.author.id) or client._users:new(data.author)
	self:_update(data)
end

property('content', '_content', function(self, content)
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success, data = client._api:editMessage(channel._id, self._id, {content = content})
	if success then self._content = data.content end
	return success
end, 'string', "The raw message text")

property('tts', '_tts', nil, 'boolean', "Whether the message is a TTS one")
property('pinned', '_pinned', nil, 'boolean', "Whether the message is pinned")
property('timestamp', '_timestamp', nil, 'string', "Date and time that the message was created")
property('editedTimestamp', '_edited_timestamp', nil, 'string', "Date and time that the message was edited")
property('channel', '_parent', nil, 'TextChannel', "The channel in which the message exists (GuildTextChannel or PrivateChannel)")
property('author', '_author', nil, 'User', "The user object representing the message's author")

property('member', function(self)
	local channel = self._parent
	if channel._is_private then return end
	return self._author:getMembership(channel._parent)
end, nil, 'Member', "The member object for the author (does not exist for private channels)")

property('guild', function(self)
	local channel = self._parent
	if not channel._is_private then return channel._parent end
end, nil, 'Guild', "The guild in which the message exists (does not exist for private channels)")

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
		for _, data in ipairs(data.mentions) do
			insert(mentions, users:get(data._id) or users:new(data))
		end
		self._mentions = mentions
	end
	if data.mention_roles ~= nil then self._mention_roles = data.mention_roles end
	-- self.embeds = data.embeds -- TODO
	-- self.attachments = data.attachments -- TODO
end

property('mentionedUsers', function(self)
	local mentions, k, v = self._mentions
	if not mentions then return function() end end
	return function()
		k, v = next(mentions, k)
		return v
	end
end, nil, 'function', "An iterator for Users that are mentions in the message")

property('mentionedRoles', function(self)
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
end, nil, 'function', "An iterator for Roles that are mentions in the message")

property('mentionedChannels', function(self)
	return wrap(function()
		local textChannels = self._parent._parent._textChannels
		for id in self._content:gmatch('<#(.-)>') do
			local channel = textChannels:get(id)
			if channel then yield(channel) end
		end
	end)
end, nil, 'function', "An iterator for GuildChannels that are mentions in the message")

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

function Message:reply(...)
	return self._parent:sendMessage(...)
end

function Message:pin()
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success, data = client._api:addPinnedChannelMessage(channel._id, self._id)
	if success then self._pinned = true end
	return success
end

function Message:unpin()
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success, data = client._api:deletePinnedChannelMessage(channel._id, self._id)
	if success then self._pinned = false end
	return success
end

function Message:delete()
	local channel = self._parent
	local client = channel._parent._parent or channel._parent
	local success, data = client._api:deleteMessage(channel._id, self._id)
	return success
end

return Message
