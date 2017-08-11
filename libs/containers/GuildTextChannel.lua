local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')
local TextChannel = require('containers/abstract/TextChannel')
local Webhook = require('containers/Webhook')
local Cache = require('iterables/Cache')
local Resolver = require('client/Resolver')

local GuildTextChannel, get = require('class')('GuildTextChannel', GuildChannel, TextChannel)

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
end

function GuildTextChannel:_load(data)
	GuildChannel._load(self, data)
	TextChannel._load(self, data)
end

--[[
@method banUser
@param id: User ID Resolveable
@param reason: string
@param days: number
@ret boolean
]]
function GuildTextChannel:createWebhook(name)
	local data, err = self.client._api:createWebhook(self._id, {name = name})
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

--[[
@method getWebhooks
@ret Cache
]]
function GuildTextChannel:getWebhooks()
	local data, err = self.client._api:getChannelWebhooks(self._id)
	if data then
		return Cache(data, Webhook, self.client)
	else
		return nil, err
	end
end

--[[
@method bulkDelete
@param Message ID Resolveables
]]
function GuildTextChannel:bulkDelete(messages)
	messages = Resolver.messageIds(messages)
	local data, err = self.client._api:bulkDeleteMessages(self._id, {messages = messages})
	if data then
		return true
	else
		return false, err
	end
end

--[[
@method setTopic
@param topic: string
@ret boolean
]]
function GuildTextChannel:setTopic(topic)
	return self:_modify({topic = topic or json.null})
end

--[[
@property topic: string|nil
]]
function get.topic(self)
	return self._topic
end

return GuildTextChannel
