local typing = require('../typing')
local json = require('json')

local Webhook = require('../containers/Webhook')

local checkType, checkInteger = typing.checkType, typing.checkInteger
local checkSnowflake = typing.checkSnowflake

local methods = {}

function methods:createWebhook(name)
	name = checkType('string', name)
	local data, err = self.client.api:createWebhook(self.id, {name = name})
	if data then
		return Webhook(data, self.client)
	else
		return nil, err
	end
end

function methods:getWebhooks()
	local data, err = self.client.api:getChannelWebhooks(self.id)
	if data then
		for i, v in ipairs(data) do
			data[i] = Webhook(v, self)
		end
		return data
	else
		return nil, err
	end
end

function methods:bulkDelete(messages)
	for i, v in ipairs(checkType('table', messages)) do
		messages[i] = checkSnowflake(v)
	end
	local data, err
	if #messages == 1 then
		data, err = self.client:deleteMessage(self.id, messages[1])
	else
		data, err = self.client:bulkDeleteMessages(self.id, {messages = messages})
	end
	if data then
		return true
	else
		return false, err
	end
end

function methods:setTopic(topic)
	return self:_modify({topic = topic and checkType('string', topic) or json.null})
end

function methods:setRateLimit(limit)
	return self:_modify({rate_limit_per_user = limit and checkInteger(limit) or json.null})
end

function methods:enableNSFW()
	return self:_modify({nsfw = true})
end

function methods:disableNSFW()
	return self:_modify({nsfw = false})
end

local getters = {}

function getters:topic()
	return self._topic
end

function getters:nsfw()
	return self._nsfw
end

function getters:rateLimit()
	return self._rate_limit_per_user or 0
end

return {
	methods = methods,
	getters = getters,
}
