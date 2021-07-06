local Snowflake = require('./Snowflake')

local json = require('json')
local class = require('../class')

local StageInstance, get = class('StageInstance', Snowflake)

function StageInstance:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = data.guild_id
	self._channel_id = data.channel_id
	self._topic = data.topic
	self._privacy_level = data.privacy_level
	self._discoverable_disabled = data.discoverable_disabled
end

function StageInstance:getGuild()
	return self.client:getGuild(self.guildId)
end

function StageInstance:getChannel()
	return self.client:getGuildChannel(self.guildId, self.channelId)
end

function StageInstance:modify(payload)
	return self.client:modifyStageInstance(self.channelId, payload)
end

function StageInstance:delete()
	return self.client:deleteStageInstance(self.channelId)
end

function StageInstance:setTopic(topic)
	return self:modify {topic = topic or json.null}
end

function StageInstance:setPrivacyLevel(privacyLevel)
	return self:modify {privacyLevel = privacyLevel or json.null}
end

function get:guildId()
	return self._guild_id
end

function get:channelId()
	return self._channel_id
end

function get:topic()
	return self._topic
end

function get:privacyLevel()
	return self._privacy_level
end

function get:discoverableDisabled()
	return self._discoverable_disabled
end

return StageInstance
