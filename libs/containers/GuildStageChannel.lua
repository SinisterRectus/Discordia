--[=[
@c GuildStageChannel x GuildVoiceChannel
@d Represents a stage channel in a Discord guild, where stage moderators can host
events with an audience.
]=]

local json = require('json')

local GuildVoiceChannel = require('containers/GuildVoiceChannel')
local StageInstance = require('voice/StageInstance')

local GuildStageChannel, get, set = require('class')('GuildStageChannel', GuildVoiceChannel)

function GuildStageChannel:__init(data, parent)
	GuildVoiceChannel.__init(self, data, parent)
	return self:_loadMore(data)
end

function GuildStageChannel:_load(data)
	GuildVoiceChannel._load(self, data)
	return self:_loadMore(data)
end

function GuildStageChannel:_loadMore(data)
    local d = self.client._api:getStageInstance(data.id)
    if d then
        self._instance = StageInstance(d, self)
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
function GuildStageChannel:setTopic(topic)
	return self:_modify({topic = topic or json.null})
end

--[=[
@m getInstance
@t http
@r StageInstance
@d Gets the Stage instance associated with the Stage channel, if it exists. If the object is already cached, then the cached
object will be returned; otherwise, an HTTP request is made.
]=]
function GuildStageChannel:getInstance()
	local instance = self._instance
	if instance then
		return instance
	else
		local data, err = self.client._api:getStageInstance(self._id)
		if data then
			instance = StageInstance(data, self)
			self._instance = instance
			return instance
		else
			return nil, err
		end
	end
end

--[=[
@m createInstance
@t http
@p topic string (1-120 characters)
@p privacyLevel number (default 2)
@r StageInstance
@d Creates a new Stage instance associated to a Stage channel.
]=]
function GuildStageChannel:createInstance(topic, privacyLevel)
	local instance = self.instance
	if instance then
		instance:setTopic(topic)
		instance:setPrivacyLevel(privacyLevel)
		return instance
	else
		local data, err = self.client._api:createStageInstance({channel_id = self._id, topic = topic, privacy_level = privacyLevel})
		if data then
			self._instance = StageInstance(data, self)
			return self._instance
		else
			return nil, err
		end
	end
end

--[=[
@m deleteInstance
@t http
@p topic string (1-120 characters)
@p privacyLevel number (default 2)
@r StageInstance
@d Deletes the Stage instance currently associated to a Stage channel.
]=]
function GuildStageChannel:deleteInstance()
	local data, err = self.client._api:deleteStageInstance(self._id)
	if data then
        self._instance = nil
		return true
	else
		return false, err
	end
end

--[=[@p instance StageInstance/nil The StageInstance for this channel if one exists.]=]
function get.instance(self)
	return self:getInstance()
end

--[=[@p topic string/nil The channel's topic. This should be between 1 and 1024 characters.]=]
function get.topic(self)
	return self._topic
end

function set.topic(self, value)
	return self:setTopic(value)
end

return GuildStageChannel