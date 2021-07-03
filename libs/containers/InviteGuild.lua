local Snowflake = require('./Snowflake')

local class = require('../class')
local typing = require('../typing')

local checkImageExtension, checkImageSize = typing.checkImageExtension, typing.checkImageSize

local InviteGuild, get = class('InviteGuild', Snowflake)

function InviteGuild:__init(data, client)
	Snowflake.__init(self, data, client)
	self._name = data.name
	self._splash = data.splash
	self._banner = data.banner
	self._description = data.description
	self._icon = data.icon
	self._features = data.features
	self._verification_level = data.verification_level
	self._vanity_url_code = data.vanity_url_code
	self._welcome_screen = data.welcome_screen and client.state:newWelcomeScreen(data.id, data.welcome_screen)
end

function InviteGuild:getIconURL(ext, size)
	if not self.icon then
		return nil, 'Guild has no icon'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildIconURL(self.id, self.icon, ext, size)
end

function InviteGuild:getBannerURL(ext, size)
	if not self.banner then
		return nil, 'Guild has no banner'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildBannerURL(self.id, self.banner, ext, size)
end

function InviteGuild:getSplashURL(ext, size)
	if not self.splash then
		return nil, 'Guild has no splash'
	end
	size = size and checkImageSize(size)
	ext = ext and checkImageExtension(ext)
	return self.client.cdn:getGuildSplashURL(self.id, self.splash, ext, size)
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

function get:welcomeScreen()
	return self._welcome_screen
end

return InviteGuild
