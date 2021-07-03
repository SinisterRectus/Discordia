local Container = require('./Container')
local WelcomeChannel = require('../structs/WelcomeChannel')

local class = require('../class')
local helpers = require('../helpers')
local json = require('json')

local WelcomeScreen, get = class('WelcomeScreen', Container)

function WelcomeScreen:__init(data, client)
	Container.__init(self, client)
	self._guild_id = assert(data.guild_id)
	self._description = data.description
	self._welcome_channels = helpers.structs(WelcomeChannel, data.welcome_channels)
end

function WelcomeScreen:__eq(other)
	return self.guildId == other.guildId
end

function WelcomeScreen:toString()
	return self.guildId
end

function WelcomeScreen:modify(payload)
	return self.client:modifyGuildWelcomeScreen(self.guildId, payload)
end

function WelcomeScreen:enable()
	return self.client:modifyGuildWelcomeScreen(self.guildId, {enabled = true})
end

function WelcomeScreen:disable()
	return self.client:modifyGuildWelcomeScreen(self.guildId, {enabled = false})
end

function WelcomeScreen:setDescription(description)
	return self.client:modifyGuildWelcomeScreen(self.guildId, {description = description or json.null})
end

function WelcomeScreen:setWelcomeChannels(welcomeChannels)
	return self.client:modifyGuildWelcomeScreen(self.guildId, {welcomeChannels = welcomeChannels or json.null})
end

function get:guildId()
	return self._guild_id
end

function get:description()
	return self._description
end

function get:welcomeChannels()
	return self._welcome_channels
end

return WelcomeScreen
