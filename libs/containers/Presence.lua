local Container = require('./Container')

local class = require('../class')

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
	return self._activities and self._activities[1] -- raw table
end

function get:activites()
	return self._activities -- raw table
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
