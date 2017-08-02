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

function GuildTextChannel:createWebhook(name)
	local data, err = self.client._api:createWebhook(self._id, {name = name})
	if data then
		return Webhook(data, self)
	else
		return nil, err
	end
end

function GuildTextChannel:getWebhooks()
	local data, err = self.client._api:getChannelWebhooks(self._id)
	if data then
		return Cache(data, Webhook, self.client)
	else
		return nil, err
	end
end

function GuildTextChannel:bulkDelete(messages)
	messages = Resolver.messageIds(messages)
	local data, err = self.client._api:bulkDeleteMessages(self._id, {messages = messages})
	if data then
		return true
	else
		return false, err
	end
end

function GuildTextChannel:setTopic(topic)
	return self:_modify({topic = topic or json.null})
end

function get.topic(self)
	return self._topic
end

return GuildTextChannel
