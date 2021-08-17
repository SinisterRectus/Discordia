--[=[
@c StageInstance x Snowflake
@d Represents a live stage.
]=]

local Snowflake = require('containers/abstract/Snowflake')
local enums = require('enums')
local json = require('json')

local StageInstance, get, set = require('class')('StageInstance', Snowflake)

function StageInstance:__init(data, channel)
	Snowflake.__init(self, data, channel)
    return self:_loadMore(data)
end

function StageInstance:_load(data)
    Snowflake._load(self, data)
    return self:_loadMore(data)
end

function StageInstance:_loadMore(data)
	if data.host_id then
		self._host = self._parent.guild:getMember(data.host_id)
	end
end

function StageInstance:_modify(payload)
	local data, err = self.client._api:modifyStageInstance(self._parent._id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

--[=[
@m delete
@t http
@r boolean
@d Permanently deletes the stage instance. This cannot be undone!
]=]
function StageInstance:delete()
	local data, err = self.client._api:deleteStageInstance(self._parent._id)
	if data then
        self._parent._instance = nil
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
@d Sets the instance's topic. This must be between 1 and 120 characters.
]=]
function StageInstance:setTopic(topic)
	return self:_modify({topic = topic or json.null})
end

--[=[
@m setPrivacyLevel
@t http
@p privacyLevel number
@r boolean
@d Sets the instance's privacy level. Cannot change privacy level when it is set to public.
See the `privacyLevel` enumeration for a human-readable representation.
]=]
function StageInstance:setPrivacyLevel(privacyLevel)
    if self._privacy_level == privacyLevel then
        return false, 'The privacy level is already set to that.'
    end
    if self._privacy_level == enums.privacyLevel.public then
        return false, 'Cannot change privacy level when it is set to public.'
    end
	return self:_modify({privacy_level = privacyLevel or json.null})
end

--[=[@p discoverableDisabled boolean Whether or not Stage Discovery is disabled.]=]
function get.discoverableDisabled(self)
	return self._discoverable_disabled
end

--[=[@p inviteCode string/nil The invite code. Will be nil if the privacyLevel is not public.]=]
function get.inviteCode(self)
	return self._invite_code
end

--[=[@p topic string The topic of the Stage instance (1-120 characters)]=]
function get.topic(self)
	return self._topic
end

--[=[@p privacyLevel number The privacy level. See the `privacyLevel` enumeration for a
human-readable representation.]=]
function get.privacyLevel(self)
	return self._privacy_level
end

function set.topic(self, value)
	return self:setTopic(value)
end

function set.privacyLevel(self, value)
	return self:setPrivacyLevel(value)
end

--[=[@p guild Guild The guild of the instance's channel. Equivalent to `StageInstance.channel.guild`.]=]
function get.guild(self)
	return self._parent.guild
end

--[=[@p channel GuildStageChannel The corresponding GuildStageChannel for
this instance.]=]
function get.channel(self)
	return self._parent
end

--[=[@p host Member/nil The member who created this stage instance, if it was cached.]=]
function get.host(self)
	return self._host
end

--[=[@p sendStartNotification boolean Whether it pings the whole server on start.]=]
function get.sendStartNotification(self)
    if self._send_start_notification == nil then return true end
	return self._send_start_notification
end

return StageInstance