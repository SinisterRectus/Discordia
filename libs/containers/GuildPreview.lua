local Snowflake = require('./Snowflake')
local Guild = require('./Guild')

local class = require('../class')
local helpers = require('../helpers')

local readOnly = helpers.readOnly

local GuildPreview, get = class('GuildPreview', Snowflake)

function GuildPreview:__init(data, client)
	Snowflake.__init(self, data, client)
	self._emojis = client.state:newGuildEmojis(self.id, data.emojis)
	self._features = data.features
end

GuildPreview.getIconURL = Guild.getIconURL
GuildPreview.getSplashURL = Guild.getSplashURL
GuildPreview.getDiscoverySplashURL = Guild.getDiscoverySplashURL

function get:name()
	return self._name
end

function get:icon()
	return self._icon
end

function get:splash()
	return self._splash
end

function get:discoverySplash()
	return self._discovery_splash
end

function get:features()
	return readOnly(self._features)
end

function get:emojis()
	return self._emojis
end

function get:description()
	return self._description
end

function get:approximateMemberCount()
	return self._approximate_member_count
end

function get:approximatePresenceCount()
	return self._approximate_presence_count
end

return GuildPreview
