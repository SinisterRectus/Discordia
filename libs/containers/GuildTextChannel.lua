local GuildChannel = require('containers/abstract/GuildChannel')
local TextChannel = require('containers/abstract/TextChannel')

local GuildTextChannel = require('class')('GuildTextChannel', GuildChannel, TextChannel)
local get = GuildTextChannel.__getters

function GuildTextChannel:__init(data, parent)
	GuildChannel.__init(self, data, parent)
	TextChannel.__init(self, data, parent)
end

function GuildTextChannel:_load(data)
	GuildChannel._load(self, data)
	TextChannel._load(self, data)
end

function get.topic(self)
	return self._topic
end

return GuildTextChannel
