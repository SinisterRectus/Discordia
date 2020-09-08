local json = require('json')

local methods = {}

function methods:createWebhook(name)
	return self.client:createWebhook(self.id, name)
end

function methods:getWebhooks()
	return self.client:getChannelWebhooks(self.id)
end

function methods:bulkDelete(messages)
	return self.client:bulkDeleteMessages(self.id, messages)
end

function methods:setTopic(topic)
	return self:modifyChannel(self.id, {topic = topic or json.null})
end

function methods:setRateLimit(limit)
	return self:modifyChannel(self.id, {rate_limit_per_user = limit or json.null})
end

function methods:enableNSFW()
	return self:modifyChannel(self.id, {nsfw = true})
end

function methods:disableNSFW()
	return self:modifyChannel(self.id, {nsfw = false})
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
