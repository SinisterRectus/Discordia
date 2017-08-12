local Snowflake = require('containers/abstract/Snowflake')
local ArrayIterable = require('iterables/ArrayIterable')

local format = string.format

local Emoji, get = require('class')('Emoji', Snowflake)

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
@property string: string
]]
function get.mentionString(self)
	return format('<:%s:%s>', self._name, self._id)
end

--[[
@property url: string
]]
function get.url(self)
	return format('https://cdn.discordapp.com/emojis/%s.png', self._id)
end

--[[
@property managed: boolean
]]
function get.managed(self)
	return self._managed
end

--[[
@property requireColons: boolean
]]
function get.requireColons(self)
	return self._require_colons
end

--[[
@property roles: ArrayIterable
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
