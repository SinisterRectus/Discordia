local Snowflake = require('./Snowflake')
local InteractionData = require('../structs/InteractionData')

local class = require('../class')

local Interaction, get = class('Interaction', Snowflake)

function Interaction:__init(data, client)
	Snowflake.__init(self, data, client)
	self._application_id = data.application_id
	self._type = data.type
	self._data = data.data and InteractionData(data.data)
	self._guild_id = data.guild_id
	self._channel_id = data.channel_id
	self._member = data.member and client.state:newMember(data.guild_id, data.member)
	self._user = data.user and client.state:newUser(data.user)
	self._token = data.token
	self._version = data.version
	self._message = data.message and client.state:newMessage(data.channel_id, data)
end

function Interaction:respond(payload)
	return self.client:createInteractionResponse(self.id, self.token, payload)
end

function Interaction:getResponse()
	return self.client:getOriginalInteractionResponse(self.applicationId, self.token)
end

function Interaction:editResponse(payload)
	return self.client:editOriginalInteractionResponse(self.applicationId, self.token, payload)
end

function Interaction:deleteResponse()
	return self.client:deleteOriginalInteractionResponse(self.applicationId, self.token)
end

function Interaction:createFollowup(payload)
	return self.client:createFollowupMessage(self.applicationId, self.token, payload)
end

function Interaction:editFollowup(messageId, payload)
	return self.client:editFollowupMessage(self.applicationId, self.token, messageId, payload)
end

function Interaction:deleteFollowup(messageId)
	return self.client:deleteFollowupMessage(self.applicationId, self.token, messageId)
end

function get:applicationId()
	return self._application_id
end

function get:type()
	return self._type
end

function get:data()
	return self._data
end

function get:guildId()
	return self._guild_id
end

function get:channelId()
	return self._channel_id
end

function get:member()
	return self._member
end

function get:user()
	return self._user
end

function get:token()
	return self._token
end

function get:version()
	return self._version
end

function get:message()
	return self._message
end

return Interaction
