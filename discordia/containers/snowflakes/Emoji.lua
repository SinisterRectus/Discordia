local Snowflake = require('../Snowflake')

local format = string.format

local Emoji, property = class('Emoji', Snowflake)
Emoji.__description = "Represents a custom Discord emoji."

function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
end

function Emoji:__tostring()
	return format('%s: %s', self.__name, self._name)
end

local function getString(self)
	return format('<:%s:%s>', self._name, self._id)
end

local function getUrl(self)
	return format("https://discordapp.com/api/emojis/%s.png", self._id)
end

property('name', '_name', nil, 'string', "Emoji name")
property('guild', '_parent', nil, 'Guild', "Discord guild in which the emoji exists")
property('managed', '_managed', nil, 'boolean', "Whether the emoji is managed by an integration")
property('requireColons', '_require_colons', nil, 'boolean', "Whether the emoji must be wrapped by colons")
property('string', getString, nil, 'string', "Discord client resolveable string similar to a mentionString")
property('url', getUrl, nil, 'string', "URL that points to the emoji's image file")

return Emoji
