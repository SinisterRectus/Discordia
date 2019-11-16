--[=[
@c GuildTextChannel x GuildChannel x TextChannel
@d Represents a text channel in a Discord guild, where guild members and webhooks
can send and receive messages.
]=]

local json = require('json')

local GuildChannel = require('containers/abstract/GuildChannel')
local TextChannel = require('containers/abstract/TextChannel')
local FilteredIterable = require('iterables/FilteredIterable')
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

--[=[
@m createWebhook
@t http
@p name string
@r Webhook
@d Creates a webhook for this channel. The name must be between 2 and 32 characters
in length.
]=]
function GuildTextChannel:createWebhook(name)
	local data, err = self.client._api:createWebhook(self._id, {name = name})
	if data then
		return Webhook(data, self.client)
	else
		return nil, err
	end
end

--[=[
@m getWebhooks
@t http
@r Cache
@d Returns a newly constructed cache of all webhook objects for the channel. The
cache and its objects are not automatically updated via gateway events. You must
call this method again to get the updated objects.
]=]
function GuildTextChannel:getWebhooks()
	local data, err = self.client._api:getChannelWebhooks(self._id)
	if data then
		return Cache(data, Webhook, self.client)
	else
		return nil, err
	end
end

--[=[
@m bulkDelete
@t http
@p messages Message-ID-Resolvables
@r boolean
@d Bulk deletes multiple messages, from 2 to 100, from the channel. Messages over
2 weeks old cannot be deleted and will return an error.
]=]
function GuildTextChannel:bulkDelete(messages)
	messages = Resolver.messageIds(messages)
	local data, err
	if #messages == 1 then
		data, err = self.client._api:deleteMessage(self._id, messages[1])
	else
		data, err = self.client._api:bulkDeleteMessages(self._id, {messages = messages})
	end
	if data then
		return true
	else
		return false, err
	end
end

--[=[
@m setTopic
@t http
@p topic string
@r boolean
@d Sets the channel's topic. This must be between 1 and 1024 characters. Pass `nil`
to remove the topic.
]=]
function GuildTextChannel:setTopic(topic)
	return self:_modify({topic = topic or json.null})
end

--[=[
@m setRateLimit
@t http
@p limit number
@r boolean
@d Sets the channel's slowmode rate limit in seconds. This must be between 0 and 120.
Passing 0 or `nil` will clear the limit.
]=]
function GuildTextChannel:setRateLimit(limit)
	return self:_modify({rate_limit_per_user = limit or json.null})
end

--[=[
@m enableNSFW
@t http
@r boolean
@d Enables the NSFW setting for the channel. NSFW channels are hidden from users
until the user explicitly requests to view them.
]=]
function GuildTextChannel:enableNSFW()
	return self:_modify({nsfw = true})
end

--[=[
@m disableNSFW
@t http
@r boolean
@d Disables the NSFW setting for the channel. NSFW channels are hidden from users
until the user explicitly requests to view them.
]=]
function GuildTextChannel:disableNSFW()
	return self:_modify({nsfw = false})
end

--[=[@p topic string/nil The channel's topic. This should be between 1 and 1024 characters.]=]
function get.topic(self)
	return self._topic
end

--[=[@p nsfw boolean Whether this channel is marked as NSFW (not safe for work).]=]
function get.nsfw(self)
	return self._nsfw or false
end

--[=[@p rateLimit number Slowmode rate limit per guild member.]=]
function get.rateLimit(self)
	return self._rate_limit_per_user or 0
end

--[=[@p isNews boolean Whether this channel is a news channel of type 5.]=]
function get.isNews(self)
	return self._type == 5
end

--[=[@p members FilteredIterable A filtered iterable of guild members that have
permission to read this channel. If you want to check whether a specific member
has permission to read this channel, it would be better to get the member object
elsewhere and use `Member:hasPermission` rather than check whether the member
exists here.]=]
function get.members(self)
	if not self._members then
		self._members = FilteredIterable(self._parent._members, function(m)
			return m:hasPermission(self, 'readMessages')
		end)
	end
	return self._members
end

return GuildTextChannel
