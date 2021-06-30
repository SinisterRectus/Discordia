local Snowflake = require('./Snowflake')

local json = require('json')
local class = require('../class')

local format = string.format

local Channel, get = class('Channel', Snowflake)

--[[
Guild Text     = 0
Private        = 1
Guild Voice    = 2
Group          = 3
Guild Category = 4
Guild News     = 5
Guild Store    = 6
]]

function Channel:__init(data, client)

	Snowflake.__init(self, data, client)
	self._guild_id = data.guild_id -- text, voice, category, news, store (excludes private and group)
	self._type = data.type -- all types
	self._name = data.name -- text, voice, group, category, news, store (excludes private)
	self._topic = data.topic -- text, news
	self._nsfw = data.nsfw -- text, news, store
	self._position = data.position -- text, voice, category, news, store (excludes private and group)
	self._icon = data.icon -- group
	self._owner_id = data.owner_id -- group
	self._application_id = data.application_id -- group
	self._parent_id = data.parent_id -- text, voice, news, store (excludes private, group, category)
	self._last_pin_timestamp = data.last_pin_timestamp -- text, news, private
	self._bitrate = data.bitrate -- voice
	self._user_limit = data.user_limit -- voice
	self._rate_limit_per_user = data.rate_limit_per_user -- text

	if data.permission_overwrites then -- text, voice, category, news, store (excludes private and group)
		self._permission_overwrites = client.state:newPermissionOverwrites(data.id, data.permission_overwrites)
	end

	if data.recipients then -- private, group
		self._recipients = client.state:newUsers(data.recipients)
	end

end

-- TODO: join/leave voice channel

function Channel:getGuild()
	if not self.guildId then
		return nil, 'Not a guild channel'
	else
		return self.client:getGuild(self.guildId)
	end
end

function Channel:getParent()
	if not self.parentId then
		return nil, 'Not a child channel'
	else
		return self.client:getGuildChannel(self.parentId)
	end
end

function Channel:delete()
	return self.client:deleteChannel(self.id)
end

function Channel:createInvite(payload)
	return self.client:createChannelInvite(self.id, payload)
end

function Channel:getInvites()
	return self.client:getChannelInvites(self.id)
end

function Channel:getMessage(id)
	return self.client:getChannelMessage(self.id, id)
end

function Channel:getFirstMessage()
	return self.client:getChannelFirstMessage(self.id)
end

function Channel:getLastMessage()
	return self.client:getChannelLastMessage(self.id)
end

function Channel:getMessages(limit, whence, messageId)
	return self.client:getChannelMessages(self.id, limit, whence, messageId)
end

function Channel:getPinnedMessages()
	return self.client:getPinnedMessages(self.id)
end

function Channel:bulkDelete(messageIds)
	return self.client:bulkDeleteMessages(self.id, messageIds)
end

function Channel:editPermissions(overwriteId, payload)
	return self.client:editChannelPermissions(self.id, overwriteId, payload)
end

function Channel:triggerTyping()
	return self.client:triggerTypingIndicator(self.id)
end

function Channel:send(payload)
	return self.client:createMessage(self.id, payload)
end

function Channel:createWebhook(payload)
	return self.client:createWebhook(self.id, payload)
end

function Channel:getWebhooks()
	return self.client:getChannelWebhooks(self.id)
end

function Channel:follow(targetId)
	return self.client:followNewsChannel(self.id, targetId)
end

function Channel:setName(name)
	return self.client:modifyChannel(self.id, {name = name or json.null})
end

function Channel:setCategory(parentId)
	return self.client:modifyChannel(self.id, {parentId = parentId or json.null})
end

function Channel:setTopic(topic)
	return self.client:modifyChannel(self.id, {topic = topic or json.null})
end

function Channel:enableNSFW()
	return self.client:modifyChannel(self.id, {nsfw = true})
end

function Channel:disableNSFW()
	return self.client:modifyChannel(self.id, {nsfw = false})
end

function Channel:setRateLimit(rateLimit)
	return self.client:modifyChannel(self.id, {rateLimit = rateLimit or json.null})
end

function Channel:setBitrate(bitrate)
	return self.client:modifyChannel(self.id, {bitrate = bitrate or json.null})
end

function Channel:setUserLimit(userLimit)
	return self.client:modifyChannel(self.id, {userLimit = userLimit or json.null})
end

function Channel:setPosition(position)
	return self.client:modifyChannel(self.id, {position = position or json.null})
end

function Channel:toMention()
	return format('<#%s>', self.id)
end

----

function get:permissionOverwrites()
	return self._permission_overwrites
end

function get:recipient()
	return self._recipients:get(1)
end

function get:recipients()
	return self._recipients
end

function get:type()
	return self._type
end

function get:name()
	return self._name
end

function get:position()
	return self._position
end

function get:guildId()
	return self._guild_id
end

function get:parentId()
	return self._parent_id
end

function get:topic()
	return self._topic
end

function get:nsfw()
	return self._nsfw
end

function get:rateLimit()
	return self._rate_limit_per_user or 0
end

function get:bitrate()
	return self._bitrate
end

function get:userLimit()
	return self._user_limit
end

return Channel
