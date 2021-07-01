local class = require('../class')

local InviteGuild, get = class('InviteGuild')

function InviteGuild:__init(data)
	self._id = data.id
	self._name = data.name
	self._splash = data.splash
	self._banner = data.banner
	self._description = data.description
	self._icon = data.icon
	self._features = data.features
	self._verification_level = data.verification_level
	self._vanity_url_code = data.vanity_url_code
end

function get:id()
	return self._id
end

function get:name()
	return self._name
end

function get:splash()
	return self._splash
end

function get:banner()
	return self._banner
end

function get:description()
	return self._description
end

function get:icon()
	return self._icon
end

function get:features()
	return self._features
end

function get:verificationLevel()
	return self._verification_level
end

function get:vanityCode()
	return self._vanity_url_code
end

return InviteGuild
