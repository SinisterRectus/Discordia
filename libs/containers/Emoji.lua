local Snowflake = require('containers/abstract/Snowflake')

local format = string.format

local Emoji = require('class')('Emoji', Snowflake)
local get = Emoji.__getters

function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function get.name(self)
	return self._name
end

function get.guild(self)
	return self._parent
end

function get.string(self)
	return format('<:%s:%s>', self._name, self._id)
end

function get.url(self)
	return format('https://cdn.discordapp.com/emojis/%s.png', self._id)
end

function get.managed(self)
	return self._managed
end

function get.requireColons(self)
	return self._require_colons
end

return Emoji
