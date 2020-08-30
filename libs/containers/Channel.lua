local Snowflake = require('./Snowflake')
local GuildChannel = require('../mixins/GuildChannel')
local GuildTextChannel = require('../mixins/GuildTextChannel')
local GuildVoiceChannel = require('../mixins/GuildVoiceChannel')
local TextChannel = require('../mixins/TextChannel')

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

class.mixin(Channel, GuildChannel.methods)
class.mixin(Channel, GuildTextChannel.methods)
class.mixin(Channel, GuildVoiceChannel.methods)
class.mixin(Channel, TextChannel.methods)

class.mixin(get, GuildChannel.getters)
class.mixin(get, GuildTextChannel.getters)
class.mixin(get, GuildVoiceChannel.getters)
class.mixin(get, TextChannel.getters)

function Channel:__init(data, client)
	Snowflake.__init(self, data, client)
	self._guild_id = data.guild_id -- text, voice, category, news, store (excludes private and group)
	return self:_load(data)
end

function Channel:_load(data)
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
	-- TODO: permission overwrites -- text, voice, category, news, store (excludes private and group)
	-- TODO: recipients -- private, group
end

function Channel:_modify(payload)
	local data, err = self.client.api:modifyChannel(self.id, payload)
	if data then
		self:_load(data)
		return true
	else
		return false, err
	end
end

function Channel:delete()
	local data, err = self.client.api:deleteChannel(self.id)
	if data then
		return true
	else
		return false, err
	end
end

function get:type()
	return self._type
end

function get:mentionString()
	return format('<#%s>', self.id)
end

return Channel
