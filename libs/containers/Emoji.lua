local Snowflake = require('containers/abstract/Snowflake')
local ArrayIterable = require('iterables/ArrayIterable')

local format = string.format

local Emoji, get = require('class')('Emoji', Snowflake)

--[[
@class Emoji

Represents a custom emoji object usable in message content and reactions.
Standard unicode emojis do not have a class; they are just strings.
]]
function Emoji:__init(data, parent)
	Snowflake.__init(self, data, parent)
	return self:_loadMore(data)
end

function Emoji:_load(data)
	Snowflake._load(self, data)
	return self:_loadMore(data)
end

function Emoji:_loadMore(data)
	if data.roles then
		local roles = #data.roles > 0 and data.roles or nil
		if self._roles then
			self._roles._array = roles
		else
			self._roles_raw = roles
		end
	end
end

--[[
@property name: string
]]
function get.name(self)
	return self._name
end

--[[
@property guild: Guild
]]
function get.guild(self)
	return self._parent
end

--[[
@property mentionString: string

A string that, when included in a message content, may resolve as an emoji image
in the official Discord client.
]]
function get.mentionString(self)
	return format('<:%s:%s>', self._name, self._id)
end

--[[
@property url: string

The URL that can be used to view a full version of the emoji.
]]
function get.url(self)
	return format('https://cdn.discordapp.com/emojis/%s.png', self._id)
end

--[[
@property managed: boolean

Whether this emoji is managed by an integration such as Twitch or YouTube.
]]
function get.managed(self)
	return self._managed
end

--[[
@property requireColons: boolean

Whether this emoji requires colons to be used in the official Discord client.
]]
function get.requireColons(self)
	return self._require_colons
end

--[[
@property roles: ArrayIterable

An iterable array of roles that may be required to use this emoji, generally
related to integration-managed emojis. Object order is not guaranteed.
]]
function get.roles(self)
	if not self._roles then
		local roles = self._parent._roles
		self._roles = ArrayIterable(self._roles_raw, function(id)
			return roles:get(id)
		end)
		self._roles_raw = nil
	end
	return self._roles
end

return Emoji
