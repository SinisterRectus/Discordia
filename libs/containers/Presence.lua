local Container = require('./Container')

local class = require('../class')
local helpers = require('../helpers')

local readOnly = helpers.readOnly

local Presence, get = class('PResence', Container)

function Presence:__init(data, client)
	Container.__init(self, client)
	self._user_id = data.user.id
	self._guild_id = data.guild_id
	self._status = data.status
	self._activities = data.activities
	if data.client_status then
		self._desktop_status = data.client_status.desktop
		self._mobile_status = data.client_status.mobile
		self._web_status = data.client_status.web
	end
end

function Presence:getUser()
	return self.client:getUser(self.userId)
end

function Presence:getGuild()
	return self.client:getGuild(self.guildId)
end

function Presence:getMember()
	return self.client:getGuildMember(self.guildId, self.userId)
end

function get:guildId()
	return self._guild_id
end

function get:userId()
	return self._user_id
end

function get:activity()
	return self.activities[1]
end

function get:activites()
	return readOnly(self._activities)
end

function get:status()
	return self._status or 'offline'
end

function get:desktopStatus()
	return self._desktop_status or 'offline'
end

function get:mobileStatus()
	return self._mobile_status or 'offline'
end

function get:webStatus()
	return self._web_status or 'offline'
end

return Presence
